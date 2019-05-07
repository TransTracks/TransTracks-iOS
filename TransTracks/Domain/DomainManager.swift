//
//  DomainManager.swift
//  TransTracks
//
//  Created by Cassie Wilson on 14/3/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

class DomainManager {
    let dataController: DataController
    
    init(dataController: DataController) {
        self.dataController = dataController
    }
    
    lazy var assignPhotoDomain: AssignPhotoDomain = AssignPhotoDomain(dataController: dataController)
    
    lazy var editPhotoDomain: EditPhotoDomain = EditPhotoDomain()
    
    lazy var homeDomain: HomeDomain = HomeDomain(dataController: dataController)
}
