//
//  MilestonesDomain.swift
//  TransTracks
//
//  Created by Cassie Wilson on 9/5/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import CoreData
import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt

enum MilestonesAction {
    case InitialLoad(epochDay: Int)
    case Reload
}

enum MilestonesResult {
    case Loading
    case Loaded(sections: [MilestonesSection])
}

enum MilestonesViewEffect {
    case ScrollToDay(epochDay: Int)
}

class MilestonesDomain {
    let actions: PublishRelay<MilestonesAction> = PublishRelay()
    
    private let viewEffectRelay: PublishRelay<MilestonesViewEffect> = PublishRelay()
    let viewEffects: Observable<MilestonesViewEffect>
    
    var results: Observable<MilestonesResult>!
    
    init(dataController: DataController){
        viewEffects = viewEffectRelay.asObservable()
        results = actions
            .apply(milestonesActionsToResults(dataController, viewEffectRelay))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .replay(1)
            .refCount()
    }
}

func milestonesActionsToResults(_ dataController: DataController, _ viewEffectRelay:PublishRelay<MilestonesViewEffect>) -> ObservableTransformer<MilestonesAction, MilestonesResult> {
    func getObservableFromAction(action: MilestonesAction) -> Observable<MilestonesResult> {
        switch action {
        case .InitialLoad(let epochDay):
            return loadingObservable(epochDay: epochDay)
        case .Reload:
            return loadingObservable()
        }
    }
    
    func loadingObservable(epochDay: Int? = nil) -> Observable<MilestonesResult> {
        return Observable.just(MilestonesResult.Loading)
            .map { _ in
                let request: NSFetchRequest<Milestone> = Milestone.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: Milestone.FIELD_EPOCH_DAY, ascending: false), NSSortDescriptor(key: Milestone.FIELD_TIMESTAMP, ascending: true)]
                
                var sections: [MilestonesSection] = []
                
                if let milestones = try? dataController.backgroundContext.fetch(request) {
                    for milestone in milestones {
                        var currentSection = sections.last
                        
                        if currentSection == nil || currentSection!.epochDay != milestone.epochDay {
                            currentSection = MilestonesSection(epochDay: milestone.epochDay)
                            sections.append(currentSection!)
                        }
                        
                        currentSection!.milestones.append(milestone)
                    }
                }
                
                if let epochDay = epochDay {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                        viewEffectRelay.accept(.ScrollToDay(epochDay: epochDay))
                    }
                }
                
                return MilestonesResult.Loaded(sections: sections)
            }
            .startWith(MilestonesResult.Loading)
    }
    
    return { actions in
        actions.flatMapLatest{
            getObservableFromAction(action: $0)
        }
    }
}
