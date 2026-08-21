import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    PracticeSheetPrintChannel.register(with: engineBridge.applicationRegistrar.messenger())
  }
}

/// iOS 原生打印：用 `printingItem` 直接打开系统打印面板。
///
/// `printing` 插件在 SPM 静态链接 + App Store strip 后，FFI `setDocument` 符号会丢失，
/// `Printing.layoutPdf` 收不到 PDF，表现为点击打印无界面。Android 走 MethodChannel，不受影响。
enum PracticeSheetPrintChannel {
  static let name = "com.leoxp.handwritingpractice/print"

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "printPdf" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let typed = args["bytes"] as? FlutterStandardTypedData
      else {
        result(
          FlutterError(
            code: "bad_args",
            message: "printPdf requires PDF bytes",
            details: nil
          )
        )
        return
      }

      let jobName = (args["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
      let landscape = (args["landscape"] as? Bool) ?? true
      presentPrint(data: typed.data, jobName: jobName, landscape: landscape, result: result)
    }
  }

  private static func presentPrint(
    data: Data,
    jobName: String?,
    landscape: Bool,
    result: @escaping FlutterResult
  ) {
    guard UIPrintInteractionController.isPrintingAvailable else {
      result(
        FlutterError(
          code: "unavailable",
          message: "Printing is not available on this device",
          details: nil
        )
      )
      return
    }

    DispatchQueue.main.async {
      let controller = UIPrintInteractionController.shared
      let info = UIPrintInfo.printInfo()
      info.jobName = (jobName?.isEmpty == false) ? jobName! : "Document"
      info.outputType = .general
      if landscape {
        info.orientation = .landscape
      }
      controller.printInfo = info
      controller.printingItem = data
      controller.showsPaperSelectionForLoadedPapers = true

      let presented = controller.present(animated: true) { _, completed, error in
        if let error {
          result(
            FlutterError(
              code: "print_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
          return
        }
        result(completed)
      }

      if !presented {
        result(
          FlutterError(
            code: "present_failed",
            message: "Unable to present the print dialog",
            details: nil
          )
        )
      }
    }
  }
}
