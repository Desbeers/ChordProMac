//
//  AppKitUtils+SplitView.swift
//  ChordProMac
//
//  Created by Nick Berendsen on 29/10/2024.
//

import SwiftUI



//struct ContentView: View {
//    var body: some View {
//
//        // if spacing is not set to zero, there will be a gap after the first row
//        // this means that you'll see a gap between the top nav and the divider
//        VStack(spacing: 0) {
//            // I'm setting a frame with minHeight for the HStack height because
//            // I don't have real content right now
//            HStack {
//                Text("This is the top nav if you like it")
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .padding(10)
//            }.frame(maxWidth: 250, minHeight: 50)
//             .background(Color.red)
//
//            // Ensure to use frames() if you see gaps everywhere
//            // or views not filling up height, then
//            // setting a frame with maxWidth/maxHeight is the missing link
//            SplitView()
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }.frame(maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
//    }
//}
//
struct PaneView: View {
    @State var text: String
    
    var body: some View {
        HStack {
            Text("Hello \(text)")
                .padding(.vertical, 30)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue)
    }
}

struct SplitView<Master: View, Detail: View>: View {
    var master: Master
    var detail: Detail

    init(@ViewBuilder master: () -> Master, @ViewBuilder detail: () -> Detail) {
        self.master = master()
        self.detail = detail()
    }

    var body: some View {
        let viewControllers = [NSHostingController(rootView: master), NSHostingController(rootView: detail)]
        return SplitViewController(viewControllers: viewControllers)
    }
}

//struct SplitView: NSViewControllerRepresentable {
//    func makeNSViewController(context: Context) -> NSViewController {
//        let controller = SplitViewController()
//
//        // I'm not sure if this has any impact
//        // controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 800, height: 800))
//
//        return controller
//    }
//
//    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
//        // nothing here
//    }
//}

struct SplitViewController: NSViewControllerRepresentable {
    var viewControllers: [NSViewController]

    private let splitViewResorationIdentifier = "com.company.restorationId:mainSplitViewController"

    func makeNSViewController(context: Context) -> NSViewController {
        let controller = NSSplitViewController()

        controller.splitView.dividerStyle = .thin
        controller.splitView.autosaveName = NSSplitView.AutosaveName(splitViewResorationIdentifier)
        controller.splitView.identifier = NSUserInterfaceItemIdentifier(rawValue: splitViewResorationIdentifier)
        let vcLeft = viewControllers[0]
        let vcRight = viewControllers[1]
        vcLeft.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 30).isActive = true
        vcRight.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 70).isActive = true
        let sidebarItem = NSSplitViewItem(contentListWithViewController: vcLeft)
        sidebarItem.canCollapse = false

        // I'm not sure if this has any impact
        // controller.view.frame = CGRect(origin: .zero, size: CGSize(width: 800, height: 800))
        controller.addSplitViewItem(sidebarItem)

        let mainItem = NSSplitViewItem(viewController: vcRight)
        controller.addSplitViewItem(mainItem)

        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        print("should update splitView", nsViewController.view.superview?.frame, nsViewController.view.frame)
    }
}
