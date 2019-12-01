//
//  StudySpotsViewController.swift
//  SpotItApp
//
//  Created by Natasha Rao on 10/29/19.
//  Copyright © 2019 Natasha Rao. All rights reserved.
//

import SwiftUI

class StudySpotsViewController: UIViewController {
    var body: some View {
        MapView()
            .frame(height: 400)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}
