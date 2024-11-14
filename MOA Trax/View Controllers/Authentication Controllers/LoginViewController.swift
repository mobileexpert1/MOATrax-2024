//
//  LoginViewController.swift
//  geolocate
//
//  Created by Appentus Technologies on 20/09/21.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn
import AuthenticationServices

class LoginViewController: UIViewController {
    
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var btnRememberMe: UIButton!
    @IBOutlet weak var txtFldEmail: UITextField!
    @IBOutlet weak var txtFldPassword: UITextField!
    
    let loginManager = LoginManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configRememberUser()
    }
    
    func configRememberUser() {
        let rememberUser = UserDefaultsUtils.retriveRememberUserValue()
        
        btnRememberMe.isSelected = rememberUser
        setLoginBtnStateSelected(rememberUser)
        
        if rememberUser {
            if let email = UserDefaultsUtils.retriveStringValue(for: .emailAddress), let password = UserDefaultsUtils.retriveStringValue(for: .password), let authType = UserDefaultsUtils.retriveStringValue(for: .authType) {
                if authType != LoginType.orbis.rawValue {
                    return
                }
                self.txtFldEmail.text = email
                self.txtFldPassword.text = password
            }
        }
    }
    
    func setLoginBtnStateSelected(_ success: Bool) {
        btnLogin.isUserInteractionEnabled = success
        btnLogin.backgroundColor = success ? UIColor.init(named: "#1E4051") : UIColor.init(named: "#AAC3CE")
    }
    
    func checkFieldsValidity() -> ValidationResult {
        let request = LoginRequest.init(email: self.txtFldEmail.text!, password: txtFldPassword.text!, authenticationType: .orbis, authorizationKey: nil)
        let validator = LoginValidation()
        return validator.validate(request: request)
    }
    
    @IBAction func textFieldValueChanged(_ textfield: UITextField) {
        let validationResult = checkFieldsValidity()
        setLoginBtnStateSelected(validationResult.success)
    }
    
    @IBAction func showPasswordAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        txtFldPassword.isSecureTextEntry = sender.isSelected
    }
    
    @IBAction func rememberMeAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func logInAction() {
        loginUser()
    }
    
    @IBAction func logInWithSocailAction(sender: UIButton) {
        if sender.tag == 1 {
            self.authoriseAppleAppleUser()
        } else if sender.tag == 2 {
            self.authoriseGoogleUser()
        } else {
            self.authorizeFacebookUser()
        }
    }
    
}

// MARK: - UITextfield Delegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Login API

extension LoginViewController {
    
    func rememberUserInfo() {
        UserDefaultsUtils.saveRememberUserValue(btnRememberMe.isSelected)
        UserDefaultsUtils.saveValue(btnRememberMe.isSelected ? (txtFldEmail.text ?? "") : "", key: .emailAddress)
        UserDefaultsUtils.saveValue(btnRememberMe.isSelected ? (txtFldPassword.text ?? "") : "", key: .password)
    }
    
    func loginUser() {
        
        // login request
        
        let request = LoginRequest.init(email: self.txtFldEmail.text!, password: txtFldPassword.text!, authenticationType: .orbis, authorizationKey: nil)
        
        // login validation
        
        let validation = LoginValidation()
        let validationResult = validation.validate(request: request)
        
        if validationResult.success {
            let loginResource = LoginResource()
            
            Loader.shared.showSpinner()
            
            // login resource
            
            loginResource.loginUser(with: request) { response, error in
                if let error = error {
                    debugPrint(error)
                    ToastUtils.shared.showToast(with: error)
                    Loader.shared.hideSpinner()
                } else {
                    // login result
                    Loader.shared.hideSpinner()
                    if let result = response {
                        if result.statusCode == .success {
                            if let userModel = response?.model {
                                self.rememberUserInfo()
                                UserDefaultsUtils.setLogInDetailsToUserDefault(with: userModel)
                                self.navigationController?.push(viewController: HomeRoute.homeViewController.controller, transitionType: .fade, duration: 0.3)
                                return
                            }
                            ToastUtils.shared.showToast(with: result.message ?? "")
                        } else {
                            debugPrint("errror")
                            ToastUtils.shared.showToast(with: result.message ?? "")
                        }
                    } else {
                        ToastUtils.shared.showToast(with: HUErrorMessage.emptyResponse.rawValue)
                    }
                }
            }
        } else {
            // error in validation
            ToastUtils.shared.showToast(with: validationResult.message)
        }
    }
}

// MARK: - Login With Social Media

extension LoginViewController {
    func logInWithSocialMedia(with request: LoginRequest) {
        
        Loader.shared.showSpinner()
        
        let loginResource = LoginResource()
        // login resource
        
        loginResource.loginUser(with: request) { response, error in
            if let error = error {
                debugPrint(error)
                ToastUtils.shared.showToast(with: error)
                Loader.shared.hideSpinner()
            } else {
                // login result
                Loader.shared.hideSpinner()
                if let result = response {
                    if result.statusCode == .success {
                        if let userModel = response?.model {
                            UserDefaultsUtils.setLogInDetailsToUserDefault(with: userModel)
                            self.navigationController?.push(viewController: HomeRoute.homeViewController.controller, transitionType: .fade, duration: 0.3)
                            return
                        }
                        ToastUtils.shared.showToast(with: result.message ?? "")
                    } else {
                        debugPrint("errror")
                        ToastUtils.shared.showToast(with: result.message ?? "")
                    }
                } else {
                    ToastUtils.shared.showToast(with: HUErrorMessage.emptyResponse.rawValue)
                }
            }
        }
    }
    
}

// MARK: - Authorize Socail Login User

extension LoginViewController {
    func authoriseGoogleUser() {
        let signInConfig = GIDConfiguration.init(clientID: KeyHolder.GoogleKeys.googleClientId.rawValue)
        GIDSignIn.sharedInstance.configuration = signInConfig
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            guard error == nil else { return }
            guard let user = result?.user else { return }
            let emailAddress = user.profile?.email
            // let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            if let idToken = user.idToken {
                let token = "\(idToken)"
                let loginRequest = LoginRequest.init(email: emailAddress ?? "", password: "", authenticationType: .google, authorizationKey: token)
                self.logInWithSocialMedia(with: loginRequest)
            }
        }
        
      /*
       GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: self) { user, error in
           guard error == nil else { return }
           
           guard let user = user else { return }
           
           let emailAddress = user.profile?.email
           // let profilePicUrl = user.profile?.imageURL(withDimension: 320)
           user.authentication.do { authentication, error in
               guard error == nil else { return }
               guard let authentication = authentication else { return }
               
               let idToken = authentication.idToken
               
               let loginRequest = LoginRequest.init(email: emailAddress ?? "", password: "", authenticationType: .google, authorizationKey: idToken)
               self.logInWithSocialMedia(with: loginRequest)
           }
       }
       */
        

    }
    
    private func authorizeFacebookUser() {

        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
            if let result = result {
                if result.isCancelled {
                    ToastUtils.shared.showToast(with: "User Canceled the login flow")
                } else {
                    if result.grantedPermissions.contains("email") {
                        self.fetchFacebookAuthUserDetails()
                    } else {
                        ToastUtils.shared.showToast(with: "Email read permission not granted by facebook")
                    }
                }
            } else {
                ToastUtils.shared.showToast(with: error?.localizedDescription ?? "")
            }
        }
    }
    private func fetchFacebookAuthUserDetails() {
        let fbManager = LoginManager()
        Loader.shared.showSpinner()
        
        let resource = FacebookAuthenticationResource()
        resource.fetchUser { fbUser, error  in
            
            Loader.shared.hideSpinner()
            
            if let error = error {
                ToastUtils.shared.showToast(with: error)
            } else {
                fbManager.logOut()
                
                guard let fbUser = fbUser else {
                    debugPrint("Fb user details not received.")
                    return
                }
                let loginRequest = LoginRequest.init(email: fbUser.email, password: "", authenticationType: .facebook, authorizationKey: fbUser.socialId)
                self.logInWithSocialMedia(with: loginRequest)
            }
        }
    }
}

// MARK: - Login WIth Apple API

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authoriseAppleAppleUser() {
        if #available(iOS 13.0, *) {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        } else {
            ToastUtils.shared.showToast(with: "Login with apple is only accessible for ios version 13 and later")
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        ToastUtils.shared.showToast(with: error.localizedDescription)
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            let request = AppleAuthDecodeRequest.init(credencials: appleIDCredential)
            let resource = AppleAuthDecodeResource.init()
            
            Loader.shared.showSpinner()
            
            resource.fetchUserDetails(with: request) { result, error in
                Loader.shared.hideSpinner()
                if let error = error {
                    ToastUtils.shared.showToast(with: error)
                } else {
                    let loginRequest = LoginRequest.init(email: result?.email ?? "", password: "", authenticationType: .apple, authorizationKey: result?.sub)
                    self.logInWithSocialMedia(with: loginRequest)
                }
            }
        } else {
            ToastUtils.shared.showToast(with: "Error in fetching user auth creds from apple.")
        }
        
    }
    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        self.view.window!
    }
}
