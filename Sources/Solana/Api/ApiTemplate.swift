public protocol ApiTemplate {
    associatedtype Success

    func perform(withConfigurationFrom actionClass: Api,
                 completion: @escaping (Result<Success, Error>) -> Void)
    @available(iOS 13.0, *)
@available(macOS 10.15, *)
    func perform(withConfigurationFrom actionClass: Api) async throws -> Success
}

extension ApiTemplate {
    @available(iOS 13.0, *)
@available(macOS 10.15, *)
    public func perform(withConfigurationFrom actionClass: Api) async throws -> Success {
        try await withCheckedThrowingContinuation { c in
            self.perform(withConfigurationFrom: actionClass, completion: c.resume(with:))
        }
    }
}

public extension Api {
    func perform<ApiType: ApiTemplate>(_ modeledApi: ApiType,
                                       completion: @escaping (Result<ApiType.Success, Error>) -> Void) {
        modeledApi.perform(withConfigurationFrom: self, completion: completion)
    }
    @available(iOS 13.0, *)
@available(macOS 10.15, *)
    func perform<ApiType: ApiTemplate>(_ modeledApi: ApiType) async throws -> ApiType.Success {
        try await withCheckedThrowingContinuation { c in
            self.perform(modeledApi, completion: c.resume(with:))
        }
    }
    
}

public enum ApiTemplates {}
