//
//  OrderDetailView.swift
//  TestDrive
//
//  Created by Richard Witherspoon on 10/6/25.
//

import SwiftUI

/// View displaying detailed order information (Level 2).
struct OrderDetailView: View {
    private let viewModel: OrderDetailViewModel

    // MARK: - Initializer

    /// Creates an order detail view.
    /// - Parameter viewModel: The view model managing order details.
    init(viewModel: OrderDetailViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        List {
            Section("Order Information") {
                LabeledContent("Order Number", value: viewModel.order.orderNumber)
                LabeledContent("Date", value: viewModel.formattedDate())
                LabeledContent("Status", value: viewModel.order.status.rawValue)
            }

            Section("Items") {
                ForEach(viewModel.order.items) { item in
                    NavigationLink(value: item) {
                        itemRow(for: item)
                    }
                }
            }

            Section("Order Summary") {
                LabeledContent("Subtotal") {
                    Text("$\(viewModel.calculateSubtotal(), specifier: "%.2f")")
                }
                LabeledContent("Tax") {
                    Text("$\(viewModel.calculateTax(), specifier: "%.2f")")
                }
                LabeledContent("Total") {
                    Text("$\(viewModel.order.total, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: OrderItem.self) { item in
            OrderItemView(viewModel: viewModel.makeOrderItemViewModel(for: item))
        }
    }

    // MARK: - Private Views

    private func itemRow(for item: OrderItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.body)
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("$\(item.totalPrice, specifier: "%.2f")")
                .fontWeight(.medium)
        }
    }
}

#Preview {
    NavigationStack {
        OrderDetailView(
            viewModel: OrderDetailViewModel(
                order: Order(
                    orderNumber: "ORD-001",
                    date: Date(),
                    total: 129.99,
                    status: .delivered,
                    items: [
                        OrderItem(productName: "Wireless Headphones", quantity: 1, price: 79.99),
                        OrderItem(productName: "Phone Case", quantity: 2, price: 25.00)
                    ]
                ),
                user: User(name: "John Doe", email: "john@example.com")
            )
        )
    }
}
