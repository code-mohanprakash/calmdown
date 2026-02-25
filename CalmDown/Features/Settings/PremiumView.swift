import SwiftUI
import StoreKit

struct PremiumView: View {
    @StateObject private var storeKit = StoreKitService.shared
    @State private var selectedProduct: Product?
    @Environment(\.dismiss) private var dismiss

    let features: [PremiumFeature] = [
        PremiumFeature(icon: "moon.stars.fill",      color: .calmLavender, title: "Sleep Analysis",       description: "Deep sleep insights & HRV during sleep"),
        PremiumFeature(icon: "face.smiling.fill",    color: .calmPink,     title: "Mood Tracking",        description: "Log emotions and discover stress patterns"),
        PremiumFeature(icon: "wind",                 color: .calmMint,     title: "Breathing Exercises",  description: "Guided 4-4-6 breathing sessions"),
        PremiumFeature(icon: "chart.xyaxis.line",    color: .chartBlue,    title: "Advanced Analytics",   description: "Monthly & yearly HRV trend analysis"),
        PremiumFeature(icon: "bell.badge.fill",      color: .calmCoral,    title: "Smart Alerts",         description: "Personalized stress notifications"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.xl) {
                    // Hero
                    heroSection

                    // Feature list
                    featuresSection

                    // Pricing options
                    if !storeKit.products.isEmpty {
                        pricingSection
                    } else {
                        ProgressView()
                            .padding()
                    }

                    // CTA
                    ctaSection

                    // Footer
                    footerSection

                    Spacer(minLength: Spacing.xxl)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
            }
            .navigationTitle("CalmDown Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task { await storeKit.loadProducts() }
    }

    // MARK: - Subviews
    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.calmMint.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)

                MrFizzView(stressLevel: .great, size: 100)
            }

            Text("Unlock Your Full Wellness Potential")
                .font(.calmTitle2)
                .multilineTextAlignment(.center)

            Text("Join thousands of users who've reduced stress and improved their wellbeing with CalmDown Premium.")
                .font(.calmBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresSection: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(features) { feature in
                HStack(spacing: Spacing.md) {
                    Image(systemName: feature.icon)
                        .font(.title2)
                        .foregroundStyle(feature.color)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.calmHeadline)
                        Text(feature.description)
                            .font(.calmCaption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.calmMint)
                }
                .padding(Spacing.md)
                .liquidGlass(cornerRadius: CornerRadius.md)
            }
        }
    }

    private var pricingSection: some View {
        VStack(spacing: Spacing.sm) {
            Text("Choose Your Plan")
                .font(.calmHeadline)

            ForEach(storeKit.products) { product in
                Button {
                    selectedProduct = product
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(product.displayName)
                                .font(.calmHeadline)
                                .foregroundStyle(.primary)
                            Text(product.description)
                                .font(.calmCaption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(product.displayPrice)
                            .font(.calmMetricSM)
                            .foregroundStyle(.primary)
                    }
                    .padding(Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .fill(selectedProduct?.id == product.id ? Color.calmMint.opacity(0.15) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: CornerRadius.md)
                                    .strokeBorder(
                                        selectedProduct?.id == product.id ? Color.calmMint : Color.gray.opacity(0.3),
                                        lineWidth: selectedProduct?.id == product.id ? 2 : 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var ctaSection: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                guard let product = selectedProduct ?? storeKit.products.first else { return }
                Task {
                    _ = try? await storeKit.purchase(product)
                }
            } label: {
                Text("Start Free Trial")
                    .font(.calmHeadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [.calmMint, .calmDeepGreen],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: CornerRadius.full)
                    )
            }

            Button {
                Task { await storeKit.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.calmCaption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Cancel anytime. Prices may vary by region.")
                .font(.calmCaption2)
                .foregroundStyle(.tertiary)
            HStack(spacing: Spacing.md) {
                Link("Privacy Policy", destination: URL(string: "https://calmdown.app/privacy")!)
                Link("Terms of Use",   destination: URL(string: "https://calmdown.app/terms")!)
            }
            .font(.calmCaption2)
            .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
    }
}

struct PremiumFeature: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let description: String
}

#Preview {
    PremiumView()
}
