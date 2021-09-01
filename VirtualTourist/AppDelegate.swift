

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "VirtualTourist")
    var travelLocationsMapViewController: TravelLocationsMapViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()

        injectDependencies()

        return true
    }

    private func saveMapRegion() {
        MapRegionDataSource.saveMapRegion(travelLocationsMapViewController.currentMapRegion)
    }
    

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveMapRegion()
        saveViewContext()
    }
    

    private func saveViewContext() {
        try? dataController.viewContext.save()
    }
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        saveMapRegion()
        saveViewContext()
    }


    private func injectDependencies() {
        let navigationController = window?.rootViewController as! UINavigationController
        travelLocationsMapViewController = navigationController.topViewController as? TravelLocationsMapViewController

        travelLocationsMapViewController.dataController = dataController
        travelLocationsMapViewController.gateway = FlickrGateway()
    }
}

