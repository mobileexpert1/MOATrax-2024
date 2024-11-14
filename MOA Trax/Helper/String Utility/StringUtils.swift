//
//  StringUtils.swift
//  Teesas
//
//  Created by love on 16/09/21.
//  Copyright © 2021 Appentus Technologies Pvt. Ltd. All rights reserved.
//

import Foundation
import UIKit

extension String {
    var isValidString: Bool {
        return !self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    var isValidPhoneNumber: Bool {
        let types: NSTextCheckingResult.CheckingType = [.phoneNumber]
        guard let detector = try? NSDataDetector(types: types.rawValue) else { return false }
        if let match = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.count)).first?.phoneNumber {
            return match == self
        } else {
            return false
        }
    }
    
    var isValidPassword: Bool {
        // least one uppercase,
        // least one digit
        // least one lowercase
        // least one symbol
        //  min 8 characters total
        let password = self.trimmingCharacters(in: CharacterSet.whitespaces)
        let passwordRegx = "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&<>*~:`-]).{8,}$"
        let passwordCheck = NSPredicate(format: "SELF MATCHES %@", passwordRegx)
        return passwordCheck.evaluate(with: password)
    }
    
}

extension String {
    func dateFromString(with format: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self) ?? Date()
    }
}

extension String {
    var url: URL? {
        guard let urlString = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: urlString)
    }
}
