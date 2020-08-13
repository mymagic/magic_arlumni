import UIKit
import Flutter
import Firebase
import FirebaseMLCommon
import FirebaseMLVisionAutoML
import Foundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    /// Declare path to model manifest file
    private let localModel: AutoMLLocalModel? = {
        guard let manifestPath = Bundle.main.path(
            forResource: Constant.autoMLManifestFileName,
            ofType: Constant.autoMLManifestFileType,
            inDirectory: Constant.autoMLManifestFolder
            ) else {
                print("Failed to find AutoML local model manifest file.")
                return nil
        }
        return AutoMLLocalModel(manifestPath: manifestPath)
    }()
    private lazy var vision = Vision.vision()
    private lazy var options = VisionOnDeviceAutoMLImageLabelerOptions(localModel: localModel!)
    private lazy var currentBitmap=UIImage()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)
        
        /// Create AutoML image labeler
        let CHANNEL = "com.mymagic.arlumni/helper"
        
        options.confidenceThreshold = Constant.labelConfidenceThreshold
        
        /// Create Flutter Method Channel
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let helperChannel = FlutterMethodChannel(name: CHANNEL,
                                                 binaryMessenger: controller.binaryMessenger)
        
        helperChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            // Note: this method is invoked on the UI thread.
            guard call.method == "classifyImage" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let tmp_result = result
            guard let args = call.arguments else {
                return
            }
            let myArgs = args as? [String: Any]
            let filePath = myArgs!["path"] as? String
            self!.currentBitmap = self!.convertPathToBitmap(imageUrlPath:filePath!)!
            self!.getStartupFromBitmap(image: self!.currentBitmap,tmp_result: tmp_result)
        })
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func convertPathToBitmap(imageUrlPath: String) -> UIImage? {
        print(imageUrlPath)
        if FileManager.default.fileExists(atPath: imageUrlPath) {
            let url = NSURL(fileURLWithPath: imageUrlPath)
            let data = NSData(contentsOf: url as URL)
            let image =  UIImage(data: data! as Data)
            let rotation = (.pi + .pi/2) as Float
            let newImage = image!.rotate(radians: rotation)
            /// TODO:  Improve iphone accuracy by cropping the middle. Save image in android native codes to see what images are being sent for analysis
            return newImage
        }else{
            return nil
        }
    }
    
    private func getStartupFromBitmap(image: UIImage,tmp_result:@escaping FlutterResult) {
        let image = VisionImage(image: image)
        let labeler = self.vision.onDeviceAutoMLImageLabeler(options: options)
        var resultArray = Array<String>()
        labeler.process(image) { labels, error in
            guard error == nil, let labels = labels else { return }
            // Task succeeded.
            print(labels)
            if(labels.count != 0){
                let labelText = labels[0].text
                let confidence = labels[0].confidence
                print(labelText)
                print(confidence!.stringValue)
                resultArray.append(labelText)
                resultArray.append(confidence!.stringValue)
            }
            print("Here's the result")
            print(resultArray)
            if(resultArray.count != 0){
                tmp_result(resultArray)
            }else{
                tmp_result([])
            }
        }
    }
    
    private func receiveBatteryLevel(result: FlutterResult) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        if device.batteryState == UIDevice.BatteryState.unknown {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Battery info unavailable",
                                details: nil))
        } else {
            result(Int(device.batteryLevel * 100))
        }
    }
    
    // MARK: - Constants and types
    private enum Constant {
        /// Definition of AutoML local model
        static let localAutoMLModelName = "alumni"
        static let autoMLManifestFileName = "manifest"
        static let autoMLManifestFileType = "json"
        static let autoMLManifestFolder = "model"
        
        /// Config for AutoML Image Labeler classification task.
        static let labelConfidenceThreshold: Float = 0.5
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
