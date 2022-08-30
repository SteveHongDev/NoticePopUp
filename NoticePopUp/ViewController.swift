//
//  ViewController.swift
//  NoticePopUp
//
//  Created by 홍성범 on 2022/08/30.
//

import UIKit
import FirebaseRemoteConfig
import FirebaseAnalytics

class ViewController: UIViewController {

    var remoteConfig: RemoteConfig?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        remoteConfig = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0    // 새로운 패치 인터벌을 줄인다.
        
        remoteConfig?.configSettings = settings
        remoteConfig?.setDefaults(fromPlist: "RemoteConfigDefaults")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getNotice()
    }
}

extension ViewController {
    func getNotice() {
        guard let remoteConfig = remoteConfig else { return }
        
        remoteConfig.fetch {[weak self] status, _ in
            if status == .success {
                remoteConfig.activate()
            } else {
                print("error: config not fetched")
            }
            
            guard let self = self else { return }
            
            if !self.isNoticeHidden(remoteConfig) {
                let noticeVC = NoticeViewController(nibName: "NoticeViewController", bundle: nil)
                
                noticeVC.modalPresentationStyle = .custom
                noticeVC.modalTransitionStyle = .crossDissolve
                
                let title = (remoteConfig["title"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let detail = (remoteConfig["detail"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                let date = (remoteConfig["date"].stringValue ?? "").replacingOccurrences(of: "\\n", with: "\n")
                
                noticeVC.noticeContents = (title: title, detail: detail, date: date)
                self.present(noticeVC, animated: true, completion: nil)
            } else {
                self.showEventAlert()
            }
        }
    }
    func isNoticeHidden(_ remoteConfig: RemoteConfig) -> Bool {
        return remoteConfig["isHidden"].boolValue
    }
}

// A/B Testing
extension ViewController {
    func showEventAlert() {
        guard let remoteConfig = remoteConfig else { return }
        
        remoteConfig.fetch {[weak self] status, _ in
            if status == .success {
                remoteConfig.activate()
            } else {
                print("error: config not fetched")
            }
            
            let message = remoteConfig["message"].stringValue ?? ""
            let confirmAction = UIAlertAction(title: "확인하기", style: .default) { _ in
                // Google Analytics
                Analytics.logEvent("promotion_alert", parameters: nil)
            }
            
            let cancelAction = UIAlertAction(title: "취소", style: .default, handler: nil)
            let alertController = UIAlertController(title: "깜짝 이벤트", message: message, preferredStyle: .alert)
            
            alertController.addAction(confirmAction)
            alertController.addAction(cancelAction)
            
            self?.present(alertController, animated: true, completion: nil)
        }
    }
}
