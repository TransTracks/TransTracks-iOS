//
//  HomeDomain.swift
//  TransTracks
//
//  Created by Cassie Wilson on 3/3/19.
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

enum HomeAction {
    case PreviousDay
    case LoadDay(day: Date)
    case NextDay
    case ReloadDay
}

enum HomeResult {
    case Loading(day: Date)
    case Loaded(dayString: String, showPreviousRecord: Bool, showNextRecord: Bool, startDate: Date, currentDate: Date, hasMilestones: Bool, showAds: Bool)
    
    func getDay() -> Date {
        switch self {
        case .Loading(let day):
            return day
        case .Loaded(_, _, _, _, let currentDate, _, _):
            return currentDate
        }
    }
}

class HomeDomain {
    let actions: PublishRelay<HomeAction> = PublishRelay()
    let results: Observable<HomeResult>
    
    init(dataController: DataController) {
        results = actions
            .startWith(HomeAction.LoadDay(day: Date.today()))
            .apply(homeActionsToResults(dataController))
            .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .replay(1)
            .refCount()
    }
}

func homeActionsToResults(_ dataController: DataController) -> ObservableTransformer<HomeAction, HomeResult>{
    func getLoadedResult(_ currentDate: Date) -> HomeResult {
        let startDate = UserDefaultsUtil.getStartDate()
        
        let dayString = Date.stringForPeriodBetween(start: startDate, end: currentDate)
        let currentDateEpochDay = currentDate.toEpochDay()
        
        let previousRecordCount = Photo.previousCount(currentDateEpochDay, context: dataController.viewContext)
            + Milestone.previousCount(currentDateEpochDay, context: dataController.viewContext)
        
        let nextRecordCount = Photo.nextCount(currentDateEpochDay, context: dataController.viewContext)
            + Milestone.nextCount(currentDateEpochDay, context: dataController.viewContext)
        
        let today = Date.today()
        
        let showPreviousRecord = previousRecordCount > 0 || currentDate.isAfter(today)
            || currentDate.isAfter(startDate)
        let showNextRecord = nextRecordCount > 0 || currentDate.isBefore(today)
            || currentDate.isBefore(startDate)
        
        let hasMilestones = Milestone.hasMilestones(currentDateEpochDay, context: dataController.viewContext)
        
        return HomeResult.Loaded(dayString: dayString, showPreviousRecord: showPreviousRecord, showNextRecord: showNextRecord, startDate: startDate, currentDate: currentDate, hasMilestones: hasMilestones, showAds: UserDefaultsUtil.showAds())
    }
    
    func getNextDay(_ currentDate: Date) -> Date {
        var possibleNextDays: [Int] = []
        
        let currentEpochDay = currentDate.toEpochDay()
        
        if let previousPhoto = Photo.next(currentEpochDay, context: dataController.viewContext) {
            possibleNextDays.append(Int(previousPhoto.epochDay))
        }
        
        if let previousMilestone = Milestone.next(currentEpochDay, context: dataController.viewContext) {
            possibleNextDays.append(Int(previousMilestone.epochDay))
        }
        
        let startDateEpochDay = UserDefaultsUtil.getStartDate().toEpochDay()
        if startDateEpochDay > currentEpochDay {
            possibleNextDays.append(startDateEpochDay)
        }
        
        let todayEpochDay = Date.today().toEpochDay()
        if todayEpochDay > currentEpochDay {
            possibleNextDays.append(todayEpochDay)
        }
        
        if let dayToUse = possibleNextDays.sorted().last {
            return Date.ofEpochDay(dayToUse)
        } else {
            return currentDate
        }
    }
    
    func getPreviousDay(_ currentDate: Date) -> Date {
        var possiblePreviousDays: [Int] = []
        
        let currentEpochDay = currentDate.toEpochDay()
        
        if let previousPhoto = Photo.previous(currentEpochDay, context: dataController.viewContext) {
            possiblePreviousDays.append(Int(previousPhoto.epochDay))
        }
        
        if let previousMilestone = Milestone.previous(currentEpochDay, context: dataController.viewContext) {
            possiblePreviousDays.append(Int(previousMilestone.epochDay))
        }
        
        let startDateEpochDay = UserDefaultsUtil.getStartDate().toEpochDay()
        if startDateEpochDay < currentEpochDay {
            possiblePreviousDays.append(startDateEpochDay)
        }
        
        let todayEpochDay = Date.today().toEpochDay()
        if todayEpochDay < currentEpochDay {
            possiblePreviousDays.append(todayEpochDay)
        }
        
        if let dayToUse = possiblePreviousDays.sorted().first {
            return Date.ofEpochDay(dayToUse)
        } else {
            return currentDate
        }
    }
    
    return { actions in
        actions.scan(HomeResult.Loading(day: Date.today())){ previousResult, action in
            switch(action){
            case .PreviousDay:
                return getLoadedResult(getPreviousDay(previousResult.getDay()))
            case .LoadDay(let day):
                return getLoadedResult(day)
            case .NextDay:
                return getLoadedResult(getNextDay(previousResult.getDay()))
            case .ReloadDay:
                return getLoadedResult(previousResult.getDay())
            }
        }
    }
}
