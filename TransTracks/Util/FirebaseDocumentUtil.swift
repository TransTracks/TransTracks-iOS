//
//  FirebaseDocumentUtil.swift
//  TransTracks
//
//  Created by Cassie Wilson on 8/9/19.
//  Copyright © 2019 TransTracks. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

class FirebaseDocumentUtil {
    private static let INCORRECT_PASSWORD_DOCUMENT = "incorrectPassword"
    
    private static let COUNT = "count"
    
    static func incrementIncorrectPasswordCount(){
        guard let user = Auth.auth().currentUser else { return }
        
        let document = Firestore.firestore().collection(user.uid).document(INCORRECT_PASSWORD_DOCUMENT)
        
        document.getDocument { snapshot, error in
            if let snapshot = snapshot {
                var count:Int = 0
                
                if let data = snapshot.data(){
                    count = data[COUNT] as? Int ?? 0
                }
                
                count += 1
                
                document.setData([COUNT : count])
            } else {
                document.setData([COUNT : 1])
            }
        }
    }
    
    static func clearIncorrectPasswordCount(){
        guard let user = Auth.auth().currentUser else { return }
        
        Firestore.firestore().collection(user.uid).document(INCORRECT_PASSWORD_DOCUMENT).delete()
    }
}
