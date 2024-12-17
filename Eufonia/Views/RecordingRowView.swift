//
//  RecordingRowView.swift
//  Eufonia
//
//  Created by Juan Daniel Rodriguez Oropeza on 17.12.2024.
//

import SwiftUI

struct RecordingRowView: View {
    let recording: Recording
    let isEditing: Bool
    @Binding var selectedRecordings: Set<UUID>
    let onDelete: (Recording) -> Void
    let onEdit: (Recording) -> Void
    let onSelect: (Recording) -> Void
    let onTapNonEditing: (Recording) -> Void

    var body: some View {
        HStack {
            if isEditing {
                Button(action: {
                    withAnimation {
                        toggleSelection(for: recording)
                    }
                }) {
                    Image(systemName: selectedRecordings.contains(recording.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedRecordings.contains(recording.id) ? .blue : .gray)
                }
            }
            VStack(alignment: .leading) {
                Text(recording.name)
                    .font(.headline)
                Text(recording.date.formatted())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Velocidad: \(recording.predictionResult)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            Spacer()
            Text(recording.duration)
                .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                toggleSelection(for: recording)
            } else {
                onTapNonEditing(recording)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete(recording)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }

            Button {
                onEdit(recording)
            } label: {
                Label("Editar", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
    
    private func toggleSelection(for recording: Recording) {
        if selectedRecordings.contains(recording.id) {
            selectedRecordings.remove(recording.id)
        } else {
            selectedRecordings.insert(recording.id)
        }
    }
}
