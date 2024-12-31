//
//  PageViewController.swift
//  ArcXPVideo
//
//  Created by Mahesh Venkateswarlu on 1/12/22.
//  Copyright © 2022 The Washington Post. All rights reserved.
//

import UIKit
// swiftlint:disable force_cast
class PageViewController: UIPageViewController {

    private(set) lazy var orderedViewControllers = {
        return [self.newMediaViewController(identifier: "Media1", mediaIndex: 0),
                self.newMediaViewController(identifier: "Media2", mediaIndex: 1),
                self.newMediaViewController(identifier: "Media3", mediaIndex: 2)]
    }()

    private(set) lazy var mediaURLs = {
        return [URL(string: "https://d21rhj7n383afu.cloudfront.net/washpost-production/The_Washington_Post/20200211/5e42c3d4cff47e0001baedcc/5e42ee2046e0fb00099e96ed/mobile.m3u8")!,
        URL(string: "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8"),
        URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8")]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        // Do any additional setup after loading the view.

        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController],
                               direction: .forward,
                               animated: true,
                               completion: nil)
        }
    }

    private func newMediaViewController(identifier: String, mediaIndex: Int) -> MediaViewController {
        let mediaController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: identifier) as! MediaViewController
        mediaController.mediaURL = mediaURLs[mediaIndex]
        return mediaController
    }
}

extension PageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController as! MediaViewController) else {
            return nil
        }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }

        guard orderedViewControllers.count > previousIndex else {
            return nil
        }

        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController as! MediaViewController) else {
            return nil
        }
        let nextIndex = viewControllerIndex + 1
        guard orderedViewControllers.count != nextIndex else {
            return nil
        }

        guard orderedViewControllers.count > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
}
