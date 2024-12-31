//
//  ContentViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 8/12/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var collections: [ArcXPContent]?

    var stories: [ArcXPContent]?

    override func viewDidLoad() {
        super.viewDidLoad()

        ArcXPContentManager.client.getCollection(alias: "mobile-topstories", index: 0, size: 20) { [weak self] result in
            switch result {
            case .success(let collections):
                self?.collections = collections
                print("Collection Result received = \(collections.count)")
            case .failure(let error):
                if let contentError = error as? NetworkError {
                    if case let .URLRequestError(reason) = contentError {
                        if case let .networkUnavailable(cachedContent) = reason {
                            print("Network offline")
                            self?.collections = cachedContent as? ArcXPContentList
                        } else  if case let .serverError(statusCode, cachedContent: cachedContent) = reason {
                            print("Bad server : Status code = \(statusCode)")
                            self?.collections = cachedContent as? ArcXPContentList
                        }
                    }
                }
            }
            self?.tableView.reloadData()
        }

        Task.init {
            stories = try? await ArcXPContentManager.client.search(by: ["a"], index: 0, size: 20)
            tableView.reloadData()
        }

        ArcXPContentManager.client.getSectionList(siteHierarchy: "mobile-nav") { result in
            switch result {
            case .success(let sectionList):
                print("Navigatin Result received = \(sectionList.count)")
            case .failure(let error):
                print("Error = \(error.localizedDescription)")
            }
        }

        // Logging example
        LoggingManager.add(observer: self)
        LoggingManager.log("Initial view controller did load.", level: .info)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let contentData = sender as? ArcXPContent,
           let detailVC = segue.destination as? DetailViewController {
            detailVC.contentData = contentData
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return collections?.count ?? 0
        }

        return stories?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = UITableViewCell()

        let contentArray = indexPath.section == 0 ? collections : stories

        if let story = contentArray?[indexPath.row] {
            var content = tableViewCell.defaultContentConfiguration()

            if story.type == .gallery {
                content.image = UIImage(systemName: "photo")
            } else if story.type == .story {
                content.image = UIImage(systemName: "doc.text")
            }
            content.text = story.headlines?.basic

            tableViewCell.contentConfiguration = content
        }
        return tableViewCell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Collection" : "Search"
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contentArray = indexPath.section == 0 ? collections : stories
        performSegue(withIdentifier: "ContentDetail", sender: contentArray?[indexPath.row])
    }
}

// Logging observer example
extension ViewController: LoggingManagerObserver {
    func loggingManagerDidReportLog(message: String, level: LoggingManager.Level, metadata: [LoggingManager.Metadata]?) {
        print("Example project - ViewController: Content framework did log message: \(message)")
    }
}
