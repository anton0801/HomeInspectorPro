import Foundation
import AppsFlyerLib

// MARK: - Logging Middleware

final class LoggingMiddleware: Middleware {
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse {
        let response = await next(request, context)
        return response
    }
}

// MARK: - Lock Middleware

final class LockMiddleware: Middleware {
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse {
        // Block requests if locked (except finalize and permissions)
        if context.isLocked {
            switch request {
            case .finalizeWithEndpoint, .requestPermission, .deferPermission:
                return await next(request, context)
            default:
                return .error(MiddlewareError.invalidData)
            }
        }
        
        return await next(request, context)
    }
}

// MARK: - Storage Middleware

final class StorageMiddleware: Middleware {
    private let storage: StorageService
    
    init(storage: StorageService) {
        self.storage = storage
    }
    
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse {
        switch request {
        case .initialize:
            // Load stored state into context
            let stored = storage.loadState()
            context.tracking = stored.tracking
            context.navigation = stored.navigation
            context.endpoint = stored.endpoint
            context.mode = stored.mode
            context.isFirstLaunch = stored.isFirstLaunch
            context.permission = RequestContext.PermissionData(
                isGranted: stored.permission.isGranted,
                isDenied: stored.permission.isDenied,
                lastAsked: stored.permission.lastAsked
            )
            return await next(request, context)
            
        case .handleTracking(let data):
            let converted = data.mapValues { "\($0)" }
            context.tracking = converted
            storage.saveTracking(converted)
            return await next(request, context)
            
        case .handleNavigation(let data):
            let converted = data.mapValues { "\($0)" }
            context.navigation = converted
            storage.saveNavigation(converted)
            return await next(request, context)
            
        case .finalizeWithEndpoint(let url):
            context.endpoint = url
            context.mode = "Active"
            context.isFirstLaunch = false
            context.isLocked = true
            storage.saveEndpoint(url)
            storage.saveMode("Active")
            storage.markLaunched()
            return await next(request, context)
            
        case .requestPermission, .deferPermission:
            // Save will happen after next processes it
            let response = await next(request, context)
            storage.savePermissions(context.permission)
            return response
            
        default:
            return await next(request, context)
        }
    }
}

// MARK: - Validation Middleware

final class ValidationMiddleware: Middleware {
    private let validator: ValidationService
    
    init(validator: ValidationService) {
        self.validator = validator
    }
    
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse {
        guard case .processValidation = request else {
            return await next(request, context)
        }
        
        guard context.hasTracking() else {
            return .validationCompleted(false)
        }
        
        do {
            let isValid = try await validator.validate()
            return .validationCompleted(isValid)
        } catch {
            return .validationCompleted(false)
        }
    }
}

// MARK: - Network Middleware

final class NetworkMiddleware: Middleware {
    private let network: NetworkService
    
    init(network: NetworkService) {
        self.network = network
    }
    
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse {
        switch request {
        case .fetchAttribution(let deviceID):
            do {
                var fetched = try await network.fetchAttribution(deviceID: deviceID)
                
                // Merge navigation
                for (key, value) in context.navigation {
                    if fetched[key] == nil {
                        fetched[key] = value
                    }
                }
                
                return .attributionFetched(fetched)
            } catch {
                return .error(error)
            }
            
        case .fetchEndpoint(let tracking):
            do {
                let endpoint = try await network.fetchEndpoint(tracking: tracking)
                return .endpointFetched(endpoint)
            } catch {
                return .error(error)
            }
            
        default:
            return await next(request, context)
        }
    }
}

// MARK: - Permission Middleware

final class PermissionMiddleware: Middleware {
    private let notificationService: NotificationService
    
    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse {
        switch request {
        case .requestPermission:
            return await withCheckedContinuation { continuation in
                notificationService.requestPermission { granted in
                    if granted {
                        context.permission.isGranted = true
                        context.permission.isDenied = false
                        context.permission.lastAsked = Date()
                        self.notificationService.registerForPush()
                        continuation.resume(returning: .permissionGranted)
                    } else {
                        context.permission.isGranted = false
                        context.permission.isDenied = true
                        context.permission.lastAsked = Date()
                        continuation.resume(returning: .permissionDenied)
                    }
                }
            }
            
        case .deferPermission:
            context.permission.lastAsked = Date()
            return .permissionDeferred
            
        default:
            return await next(request, context)
        }
    }
}

// MARK: - Business Logic Middleware

final class BusinessLogicMiddleware: Middleware {
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse {
        switch request {
        case .initialize:
            return .initialized
            
        case .handleTracking:
            return .trackingStored(context.tracking)
            
        case .handleNavigation:
            return .navigationStored(context.navigation)
            
        case .networkStatusChanged(let isConnected):
            return isConnected ? .hideOfflineView : .showOfflineView
            
        case .timeout:
            return .navigateToMain
            
        case .finalizeWithEndpoint:
            if context.permission.canAsk {
                return .showPermissionPrompt
            } else {
                return .navigateToWeb
            }
            
        default:
            return await next(request, context)
        }
    }
}



typealias MiddlewareNext = (AppRequest, RequestContext) async -> AppResponse

protocol Middleware {
    func handle(
        request: AppRequest,
        context: RequestContext,
        next: @escaping MiddlewareNext
    ) async -> AppResponse
}

final class MiddlewareChain {
    private var middlewares: [Middleware] = []
    private let finalHandler: (AppRequest, RequestContext) async -> AppResponse
    
    init(finalHandler: @escaping (AppRequest, RequestContext) async -> AppResponse) {
        self.finalHandler = finalHandler
    }
    
    func use(_ middleware: Middleware) {
        middlewares.append(middleware)
    }
    
    func execute(request: AppRequest, context: RequestContext) async -> AppResponse {
        await executeChain(at: 0, request: request, context: context)
    }
    
    private func executeChain(
        at index: Int,
        request: AppRequest,
        context: RequestContext
    ) async -> AppResponse {
        if index >= middlewares.count {
            return await finalHandler(request, context)
        }
        
        let middleware = middlewares[index]
        
        let next: MiddlewareNext = { [weak self] req, ctx in
            guard let self = self else {
                return .error(MiddlewareError.invalidData)
            }
            return await self.executeChain(at: index + 1, request: req, context: ctx)
        }
        
        return await middleware.handle(request: request, context: context, next: next)
    }
}
