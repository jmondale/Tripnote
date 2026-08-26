//
//  TripnoteWidgetBundle.swift
//  TripnoteWidget
//
//  Created by Jaye Mondale on 8/25/26.
//

import WidgetKit
import SwiftUI

@main
struct TripnoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        TripnoteWidget()
        TripnoteWidgetControl()
        TripnoteWidgetLiveActivity()
    }
}
