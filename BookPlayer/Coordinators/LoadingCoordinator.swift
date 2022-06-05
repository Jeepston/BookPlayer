//
//  LoadingCoordinator.swift
//  BookPlayer
//
//  Created by Gianni Carlo on 11/9/21.
//  Copyright © 2021 Tortuga Power. All rights reserved.
//

import BookPlayerKit
import UIKit

class LoadingCoordinator: Coordinator {
  let loadingViewController: LoadingViewController

  init(
    navigationController: UINavigationController,
    loadingViewController: LoadingViewController
  ) {
    self.loadingViewController = loadingViewController

    super.init(navigationController: navigationController, flowType: .modal)

    self.loadingViewController.modalPresentationStyle = .fullScreen

    let viewModel = LoadingViewModel()
    viewModel.coordinator = self
    self.loadingViewController.viewModel = viewModel
    self.loadingViewController.presentationController?.delegate = self
  }

  override func start() {
    self.navigationController.show(self.loadingViewController, sender: self)
  }

  func didFinishLoadingSequence(coreDataStack: CoreDataStack) {
    let rootVC = RootViewController.instantiate(from: .Main)
    let coreServices = AppDelegate.shared!.createCoreServicesIfNeeded(from: coreDataStack)

    let coordinator = MainCoordinator(
      rootController: rootVC,
      coreServices: coreServices,
      navigationController: AppNavigationController.instantiate(from: .Main)
    )
    rootVC.viewModel = BaseViewModel<MainCoordinator>()
    rootVC.viewModel.coordinator = coordinator
    rootVC.modalPresentationStyle = .fullScreen
    rootVC.modalTransitionStyle = .crossDissolve
    coordinator.parentCoordinator = self
    coordinator.presentingViewController = self.presentingViewController
    self.childCoordinators.append(coordinator)

    self.navigationController.present(rootVC, animated: true, completion: nil)
  }

  override func getMainCoordinator() -> MainCoordinator? {
    return self.childCoordinators.first as? MainCoordinator
  }
}
