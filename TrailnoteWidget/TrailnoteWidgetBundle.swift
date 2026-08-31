//
//  TrailnoteWidgetBundle.swift
//  TrailnoteWidget
//
//  Created by Jaye Mondale on 8/25/26.
//

import WidgetKit
import SwiftUI

@main
struct TrailnoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        TrailnoteWidget()
        TrailnoteWidgetControl()
        TrailnoteWidgetLiveActivity()
    }
}
