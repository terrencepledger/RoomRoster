import SwiftUI

private typealias l10n = Strings.settings

struct EditRoomsView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var newRoomName = ""
    @State private var showingAddRoomPrompt = false

    var body: some View {
        List {
            if let message = viewModel.errorMessage {
                Banner.error(message)
            }
            ForEach(viewModel.rooms, id: \.id) { room in
                Text(room.label)
            }
        }
        .navigationTitle(l10n.roomsTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddRoomPrompt = true
                    HapticManager.shared.impact()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadRooms()
        }
        .alert(
            Strings.inventory.addRoom.title,
            isPresented: $showingAddRoomPrompt,
            actions: {
                TextField(
                    Strings.inventory.addRoom.placeholder,
                    text: $newRoomName
                )
                Button(Strings.inventory.addRoom.button) {
                    Task {
                        if let newRoom = await viewModel.addRoom(name: newRoomName) {
                            viewModel.rooms.append(newRoom)
                            HapticManager.shared.success()
                        }
                        newRoomName = ""
                    }
                }
                .platformButtonStyle()
                Button(Strings.general.cancel, role: .cancel) { }
            }
        )
        .onAppear { Logger.page("EditRoomsView") }
    }
}

#Preview {
    NavigationStack {
        EditRoomsView()
    }
}
