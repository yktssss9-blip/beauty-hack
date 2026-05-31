import SwiftUI

enum AddNavigation: Hashable {
    case subCategory(categoryName: String)
    case templateSchedule(categoryName: String, templateName: String)
}

struct AddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path: [AddNavigation] = []

    var body: some View {
        NavigationStack(path: $path) {
            CategorySelectView(path: $path)
                .navigationDestination(for: AddNavigation.self) { destination in
                    switch destination {
                    case .subCategory(let categoryName):
                        SubCategorySelectView(categoryName: categoryName, path: $path)
                    case .templateSchedule(let categoryName, let templateName):
                        TemplateScheduleView(categoryName: categoryName, templateName: templateName)
                    }
                }
        }
    }
}
