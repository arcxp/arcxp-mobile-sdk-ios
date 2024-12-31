//
//  UserIdentitiesViewController.swift
//  ArcXPSDKSample
//
//  Created by Cassandra Balbuena on 7/31/24.
//  Copyright © 2024 The Washington Post Company. All rights reserved.
//

import UIKit
import ArcXP

let genericTableViewCellID = "GenericTableViewCell"

/// A view that displays the identities the user has attached to their profile.
class UserIdentitiesViewController: UITableViewController {

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: genericTableViewCellID)
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Subscriptions.cachedUserProfile?.identities?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: genericTableViewCellID)!
        guard let identity = Subscriptions.cachedUserProfile?.identities?[indexPath.row] else { cell.textLabel?.text = "N/A"
            return cell
        }
        cell.textLabel?.text = "\(identity.type): \(identity.userName)"
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard let numberOfIdentities = Subscriptions.cachedUserProfile?.identities?.count,
              numberOfIdentities > 1 else {
                  // swiftlint:disable line_length
                  presentAlert(title: "Error",
                               message: "You cannot delete your last identity. At least one identity must exist. If you'd like to delete your last identity, use the \"delete account\" option.")
                  // swiftlint:enable line_length
                  // Client developer note: If this check is not done, a 400 error response is expected below.
                  // Checking here will prevent the need for an unnecessary network request.
                  return
        }
        guard let identity = Subscriptions.cachedUserProfile?.identities?[indexPath.row],
              let authService = AuthService(rawValue: identity.type.lowercased()) else {
            return
        }
        presentAlert(title: "Delete Social Login?",
                     message: "Would you like to delete your \(authService.rawValue.capitalized) account?",
                     affirmativeActonTitle: "Yes",
                     showCancelAction: true) { [weak self] _ in
            Subscriptions.Identity.removeUserIdentity(platform: authService) { result in
                switch result {
                case .success:
                    Subscriptions.cachedUserProfile?.identities?.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                case .failure(let error):
                    self?.presentAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}

extension UserIdentitiesViewController: LogInDelegate {

    func didCompleteLogIn() {
        Subscriptions.Identity.fetchUserProfile { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
            self?.tableView.reloadData()
        }
    }
}
