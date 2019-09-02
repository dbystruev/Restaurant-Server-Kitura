import Foundation
import Kitura
import KituraOpenAPI
import LoggerAPI
import Configuration
import CloudEnvironment
import KituraContracts
import Health

public let projectPath = ConfigurationManager.BasePath.project.path
public let health = Health()

public class App {
    let router = Router()
    let cloudEnv = CloudEnv()
    
    private var menuItemStore = [MenuItem]()
    private var nextId = 0
    private var workerQueue = DispatchQueue(label: "worker")

    public init() throws {
        // Run the metrics initializer
        initializeMetrics(router: router)
    }

    func postInit() throws {
        // Endpoints
        initializeHealthRoutes(app: self)
        KituraOpenAPI.addEndpoints(to: router)
        Persistence.setUp()
        
        do {
            try MenuItem.createTableSync()
        } catch let error {
            print(#line, #function, "WARNING: Table MenuItem already exists", error.localizedDescription)
        }
        
        router.delete("/", handler: deleteAllHandler)
        router.delete("/", handler: deleteOneHandler)
        router.get("/", handler: getAllHandler)
        router.get("/", handler: getOneHandler)
        router.post("/", handler: storeHandler)
    }
    
    func deleteAllHandler(completion: @escaping (RequestError?) -> Void) {
        MenuItem.deleteAll(completion)
    }
    
    func deleteOneHandler(id: Int, completion: @escaping (RequestError?) -> Void) {
        MenuItem.delete(id: id, completion)
    }
    
    func getAllHandler(completion: @escaping ([MenuItem]?, RequestError?) -> Void) {
//        completion(menuItemStore, nil)
        MenuItem.findAll(completion)
    }
    
    func getOneHandler(id: Int, completion: @escaping (MenuItem?, RequestError?) -> Void) {
//        guard let menuItem = menuItemStore.first(where: { $0.id == id }) else {
//            return completion(nil, .notFound)
//        }
//        completion(menuItem, nil)
        MenuItem.find(id: id, completion)
    }
    
    func storeHandler(menuItem: MenuItem, completion: @escaping (MenuItem?, RequestError?) -> Void) {
        guard
            let name = menuItem.name,
            !name.isEmpty,
            let price = menuItem.price,
            0 <= price
        else {
            return completion(nil, RequestError.badRequest)
        }
        var menuItem = menuItem
        menuItem.id = nextId
        menuItem.imageURL = URL(string: "\(cloudEnv.url)/images/\(nextId).jpeg")
        nextId += 1
//        execute {
//            menuItemStore.append(menuItem)
//        }
        menuItem.save(completion)
        completion(menuItem, nil)
    }
    
    func execute(_ block: () -> Void) {
        workerQueue.sync {
            block()
        }
    }

    public func run() throws {
        try postInit()
        Kitura.addHTTPServer(onPort: cloudEnv.port, with: router)
        Kitura.run()
    }
}
