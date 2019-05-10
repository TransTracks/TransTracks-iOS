//
//  MilestonesController.swift
//  TransTracks
//
//  Created by Cassie Wilson on 8/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import RxCocoa
import RxSwift
import RxSwiftExt
import UIKit

class MilestonesController: BackgroundGradientViewController {
    
    //MARK: Properties
    
    var domainManager: DomainManager!
    var initialEpochDay: Int!
    
    private var resultsDisposable: Disposable?
    private var viewDisposables: CompositeDisposable = CompositeDisposable()
    
    private var sections: [MilestonesSection] = []
    
    //MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyView: UIStackView!
    @IBOutlet weak var adViewHolder: AdContainerView!
    
    //MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        adViewHolder.setupAd("ca-app-pub-4389848400124499/6697828305", rootViewController: self)
        
        resultsDisposable = domainManager.milestonesDomain.results
            .do(onSubscribe: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.domainManager.milestonesDomain.actions.accept(.InitialLoad(epochDay: self.initialEpochDay))
                }
            })
            .subscribe()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        domainManager.milestonesDomain.actions.accept(.Reload)
        
        let _ = viewDisposables.insert(
            domainManager.milestonesDomain.results.subscribe{ result in
                guard let result = result.element else { return }
                
                switch result {
                case .Loading:
                    self.showEmptyView(true)
                    
                case .Loaded(let sections):
                    self.sections = sections
                    self.tableView.reloadData()
                    self.showEmptyView(sections.isEmpty)
                }
            }
        )
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if let addEditMilestoneController = segue.destination as? AddEditMilestoneController {
            addEditMilestoneController.domainManager = domainManager
            addEditMilestoneController.initialEpochDay = initialEpochDay
            
            if let milestone = sender as? Milestone {
                addEditMilestoneController.milestone = milestone
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDisposables.dispose()
        viewDisposables = CompositeDisposable()
    }
    
    deinit {
        resultsDisposable?.dispose()
    }
    
    //MARK: UI Helpers
    
    func showEmptyView(_ showEmptyView: Bool){
        tableView.isHidden = showEmptyView
        emptyView.isHidden = !showEmptyView
    }
    
    //MARK: Button Handling
    
    @IBAction func addClick(_ sender: Any) {
        performSegue(withIdentifier: "AddEditMilestone", sender: sender)
    }
    
    @IBAction func emptyAddClick(_ sender: Any) {
        addClick(sender)
    }
}

class MilestonesSection {
    let epochDay: Int64
    var milestones: [Milestone] = []
    
    init(epochDay: Int64){
        self.epochDay = epochDay
    }
}

extension MilestonesController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.backgroundView?.backgroundColor = UIColor.clear
            view.textLabel?.backgroundColor = UIColor.clear
            view.textLabel?.textColor = UIColor.white
            view.textLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let milestone = sections[indexPath.section].milestones[indexPath.row]
        performSegue(withIdentifier: "AddEditMilestone", sender: milestone)
    }
}

extension MilestonesController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].milestones.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Date.ofEpochDay(sections[section].epochDay).toFullDateString()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MilestoneCell", for: indexPath) as! MilestoneCell
        let milestone = sections[indexPath.section].milestones[indexPath.row]
        
        cell.title.text = milestone.title
        cell.descriptionLabel.text = milestone.userDescription
        
        return cell
    }
}
