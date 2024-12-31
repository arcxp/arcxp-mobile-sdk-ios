//
//  DetailViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 8/12/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

class DetailViewController: UIViewController {

    var contentData: ArcXPContent?

    @IBOutlet weak var contentDetailTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if let identifier = contentData?.identifier {
            ArcXPContentManager.client.getStoryContent(identifier: identifier) { [weak self] result in
                switch result {
                case .success(let stories):
                    self?.contentData = stories
                case .failure(let error):
                    if let contentError = error as? NetworkError {
                        if case let .URLRequestError(reason) = contentError {
                            if case let .networkUnavailable(cachedContent) = reason {
                                print("Network offline")
                                self?.contentData = cachedContent as? ArcXPContent
                            } else  if case let .serverError(statusCode, cachedContent: cachedContent) = reason {
                                print("Bad server : Status code = \(statusCode)")
                                self?.contentData = cachedContent as? ArcXPContent
                            }
                        }
                    }
                    print(error.localizedDescription)
                }
                self?.contentDetailTable.reloadData()
            }
        }
        // Logging example
       LoggingManager.add(observer: self)
       LoggingManager.log("DetailViewController view did load", level: .info)
    }
}

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let contentData = contentData,
           let contentElements = contentData.contentElements {
            return contentElements.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!

        if let contentElements = contentData?.contentElements {
            let content = contentElements[indexPath.row]

            var cellContentConfiguration = tableViewCell.defaultContentConfiguration()

            if content.type == "text" {
                cellContentConfiguration.text = content.content
            }

            tableViewCell.contentConfiguration = cellContentConfiguration
        }
        return tableViewCell
    }
}

// Logging observer example
extension DetailViewController: LoggingManagerObserver {
    func loggingManagerDidReportLog(message: String, level: LoggingManager.Level, metadata: [LoggingManager.Metadata]?) {
        print("Example project - DetailViewController: Content framework did log message: \(message)")
    }
}
