//
//  LoginValidation.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import Foundation

struct LoginValidation {
    func validate(request: LoginRequest) -> ValidationResult {
        if !request.email.isValidEmail {
            return ValidationResult.init(success: false, message: "Please enter email address ")
        } else if !request.password.isValidString {
            return ValidationResult.init(success: false, message: "Please enter password")
        }
        return ValidationResult.init(success: true, message: "All fields valid")
    }
}
