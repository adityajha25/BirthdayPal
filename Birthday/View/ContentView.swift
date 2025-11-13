import SwiftUI
import Contacts
import MessageUI

struct ContentView: View {
    var body: some View {
        if #available(iOS 17.0, *) {
            LandingPage()
        } else {
            Text("Requires iOS 17 or later")
        }
    }
}

@available(iOS 17.0, *)
struct LandingPage: View {
    @StateObject private var contactsVM = ContactViewModel()
    @State private var animateGradient = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Vibrant animated gradient background
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.05, blue: 0.25),
                            Color(red: 0.05, green: 0.15, blue: 0.3),
                            Color(red: 0.0, green: 0.1, blue: 0.2)
                        ],
                        startPoint: animateGradient ? .topLeading : .bottomLeading,
                        endPoint: animateGradient ? .bottomTrailing : .topTrailing
                    )
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                            animateGradient.toggle()
                        }
                    }
                    
                    // Floating orbs for depth
                    FloatingOrb(color: .purple.opacity(0.3), size: 200, position: CGPoint(x: geometry.size.width * 0.2, y: geometry.size.height * 0.15))
                    FloatingOrb(color: .blue.opacity(0.25), size: 250, position: CGPoint(x: geometry.size.width * 0.8, y: geometry.size.height * 0.4))
                    FloatingOrb(color: .cyan.opacity(0.2), size: 180, position: CGPoint(x: geometry.size.width * 0.5, y: geometry.size.height * 0.7))
                    
                    VStack(spacing: 0) {
                        // Header with glass effect
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("BirthdayPal")
                                        .font(.system(size: 36, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.white, .cyan.opacity(0.9), .blue.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    Text("Never miss a special day")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            
                            // Stats bar with glass morphism
                            HStack(spacing: 16) {
                                GlassStatPill(
                                    icon: "calendar",
                                    value: "\(contactsVM.birthdaysThisMonthCount)",
                                    label: "This Month",
                                    accentColor: .cyan
                                )
                                
                                GlassStatPill(
                                    icon: "person.2.fill",
                                    value: "\(contactsVM.contactsWithBirthday.count)",
                                    label: "Total",
                                    accentColor: .purple
                                )
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                        }
                        .padding(.bottom, 24)
                        
                        // Main content
                        if contactsVM.isLoading {
                            Spacer()
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.2)
                                Text("Loading contacts...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        } else if let error = contactsVM.errorMessage {
                            Spacer()
                            ErrorStateView(error: error) {
                                contactsVM.loadContacts()
                            }
                            Spacer()
                        } else if contactsVM.contactsWithBirthday.isEmpty {
                            Spacer()
                            EmptyStateView()
                            Spacer()
                        } else {
                            ScrollView(showsIndicators: false) {
                                VStack(spacing: 16) {
                                    // Section header
                                    HStack {
                                        Text("Upcoming")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                                    
                                    // Birthday cards
                                    ForEach(contactsVM.contactsWithBirthday) { contact in
                                        NavigationLink(destination: editView(contact: contact)) {
                                            ModernBirthdayCard(
                                                contact: contact,
                                                screenwidth: geometry.size.width
                                            )
                                        }
                                        .buttonStyle(CardButtonStyle())
                                    }
                                    
                                    // Achievement card
                                    ModernAchievementCard(rememberedCount: contactsVM.rememberedBirthdaysCount)
                                        .padding(.top, 8)
                                    
                                    // Browse by month nav
                                    NavigationLink(destination: BrowseBirthdaysView(contactsVM: contactsVM)) {
                                        ModernBrowseCard(screenwidth: geometry.size.width)
                                    }
                                    .buttonStyle(CardButtonStyle())
                                    
                                    // Bottom padding
                                    Color.clear.frame(height: 20)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            contactsVM.loadContacts()
        }
    }
}

// MARK: - Floating Orb Component

struct FloatingOrb: View {
    let color: Color
    let size: CGFloat
    let position: CGPoint
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 60)
            .position(position)
            .scaleEffect(animate ? 1.2 : 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
    }
}

// MARK: - Glass Stat Pill Component

struct GlassStatPill: View {
    let icon: String
    let value: String
    let label: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .blur(radius: 8)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        )
    }
}

// MARK: - Modern Birthday Card with Glass Effect

struct ModernBirthdayCard: View {
    var contact: Contact
    var screenwidth: CGFloat
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Date badge with glass effect
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.4), .blue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blur(radius: 15)
                
                VStack(spacing: 4) {
                    if let parts = contact.comparableBirthday?.formattedMonthDay().split(separator: " ") {
                        Text(String(parts[0]))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                        Text(String(parts[1]))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .frame(width: 64, height: 64)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                )
            }
            
            // Contact info
            VStack(alignment: .leading, spacing: 6) {
                Text(contact.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                
                if let days = contact.daysToBirthday {
                    HStack(spacing: 6) {
                        if days == 0 {
                            Image(systemName: "party.popper.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            Text("Birthday Today!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        } else {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("In \(days) day\(days == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Arrow indicator with glow
            ZStack {
                Circle()
                    .fill(.purple.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .blur(radius: 8)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .cyan.opacity(0.2), radius: 15, x: 0, y: 8)
            }
        )
        .padding(.horizontal, 24)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Modern Achievement Card with Glass Effect

struct ModernAchievementCard: View {
    let rememberedCount: Int
    @State private var shimmer = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .blur(radius: 8)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("2024 Achievement")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
            
            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You've remembered")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(rememberedCount)")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("birthdays")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.pink.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 20)
                    
                    Text("🎂")
                        .font(.system(size: 64))
                        .scaleEffect(shimmer ? 1.1 : 1.0)
                        .rotationEffect(.degrees(shimmer ? 5 : -5))
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                // Background blur layer
                RoundedRectangle(cornerRadius: 28)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .purple.opacity(0.15),
                                        .blue.opacity(0.1),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.4),
                                        .purple.opacity(0.3),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
            }
        )
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                shimmer.toggle()
            }
        }
    }
}

// MARK: - Modern Browse Card with Glass Effect

struct ModernBrowseCard: View {
    var screenwidth: CGFloat
    
    var body: some View {
        HStack(spacing: 16) {
            // Calendar icon with glass effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.4), .cyan.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blur(radius: 15)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 26))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: 64, height: 64)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Browse by Month")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text("View all birthdays")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .blur(radius: 8)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .blue.opacity(0.2), radius: 15, x: 0, y: 8)
            }
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Empty State with Glass Effect

struct EmptyStateView: View {
    @State private var float = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: "birthday.cake")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: 120, height: 120)
            }
            .offset(y: float ? -10 : 10)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: float)
            .onAppear { float = true }
            
            VStack(spacing: 8) {
                Text("No Upcoming Birthdays")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text("Add birthdays to your contacts\nto see them here")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Error State with Glass Effect

struct ErrorStateView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.red.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.red.opacity(0.4), .red.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .frame(width: 100, height: 100)
            }
            
            VStack(spacing: 12) {
                Text("Something Went Wrong")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                )
            }
        }
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Edit View with Glass Effect

struct editView: View {
    var contact: Contact
    @StateObject private var messageVM = BirthdayMessageViewModel()
    @Environment(\.dismiss) var dismiss
    @StateObject private var messageCounter = MessageCounter()
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Vibrant animated gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.25),
                    Color(red: 0.05, green: 0.15, blue: 0.3),
                    Color(red: 0.15, green: 0.05, blue: 0.25)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Floating orbs
            Circle()
                .fill(.purple.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -100, y: -150)
            
            Circle()
                .fill(.cyan.opacity(0.2))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 150, y: 200)
            
            VStack(spacing: 36) {
                // Contact header with glass effect
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.blue.opacity(0.4), .purple.opacity(0.3)],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 140, height: 140)
                            .blur(radius: 30)
                        
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            
                            Text(contact.name.prefix(1))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .cyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .frame(width: 110, height: 110)
                    }
                    
                    Text(contact.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 50)
                
                // Birthday info card with glass
                if let birthday = contact.birthday {
                    VStack(spacing: 20) {
                        Text("🎂")
                            .font(.system(size: 64))
                        
                        VStack(spacing: 10) {
                            Text("Birthday")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Text(formatBirthday(birthday))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .pink.opacity(0.1),
                                                    .purple.opacity(0.1),
                                                    .clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    .white.opacity(0.4),
                                                    .white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: .pink.opacity(0.2), radius: 20, x: 0, y: 10)
                        }
                    )
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Send message button with glass effect
                Button(action: {
                    let cnContact = convertToCNContact(contact)
                    messageVM.startBirthdayFlow(with: [cnContact])
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 18))
                        Text("Send Birthday Message")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .blue.opacity(0.7),
                                                    .cyan.opacity(0.6),
                                                    .purple.opacity(0.5)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.5), .white.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                                .shadow(color: .blue.opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $messageVM.showTemplatePicker) {
            if #available(iOS 18.0, *) {
                MessageTemplatePickerView(messageVM: messageVM)
            } else {
                Text("Template picker requires iOS 18 or later")
                    .foregroundColor(.white)
            }
        }
        .fullScreenCover(isPresented: $messageVM.showComposer) {
            if MFMessageComposeViewController.canSendText() {
                MessageComposerView(
                    recipients: messageVM.composerRecipients,
                    body: messageVM.composerBody,
                    onFinish: { result in
                        if result == .sent,
                           let cnContact = messageVM.todaysBirthdayContacts.first {
                            messageCounter.recordMessage(
                                to: cnContact.identifier,
                                message: messageVM.composerBody,
                                contactName: contact.name
                            )
                        }
                        messageVM.composerFinished()
                        dismiss()
                    }
                )
                .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    Text("Cannot Send Messages")
                        .font(.headline)
                    Text("This device is not configured to send messages.")
                        .multilineTextAlignment(.center)
                    Button("OK") {
                        messageVM.showComposer = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .alert("Error", isPresented: .constant(messageVM.lastError != nil)) {
            Button("OK") {
                messageVM.lastError = nil
            }
        } message: {
            if let error = messageVM.lastError {
                Text(error)
            }
        }
    }
    
    private func formatBirthday(_ birthday: DateComponents) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        
        if let date = Calendar.current.date(from: birthday) {
            return formatter.string(from: date)
        }
        
        if let month = birthday.month, let day = birthday.day {
            let monthName = Calendar.current.monthSymbols[month - 1]
            return "\(monthName) \(day)"
        }
        
        return "Unknown"
    }
    
    private func convertToCNContact(_ contact: Contact) -> CNContact {
        let cnContact = CNMutableContact()
        
        let nameComponents = contact.name.components(separatedBy: " ")
        if nameComponents.count > 0 {
            cnContact.givenName = nameComponents[0]
        }
        if nameComponents.count > 1 {
            cnContact.familyName = nameComponents[1...].joined(separator: " ")
        }
        
        if let phoneNumber = contact.phoneNumber {
            let phone = CNLabeledValue(label: CNLabelPhoneNumberMain, value: CNPhoneNumber(stringValue: phoneNumber))
            cnContact.phoneNumbers = [phone]
        }
        
        if let birthday = contact.birthday {
            cnContact.birthday = birthday
        }
        
        return cnContact.copy() as! CNContact
    }
}

// MARK: - BrowseBirthdaysView with Glass Effect

@available(iOS 17.0, *)
struct BrowseBirthdaysView: View {
    @State private var selectedMonth = "January"
    @State private var selectedTab: ViewMode = .byMonth
    @State private var selectedDate = Date()
    @State private var animateGradient = false
    var contactsVM: ContactViewModel

    enum ViewMode {
        case byMonth
        case calendar
    }

    let months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    var body: some View {
        ZStack {
            // Vibrant animated gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.25),
                    Color(red: 0.05, green: 0.15, blue: 0.3),
                    Color(red: 0.0, green: 0.1, blue: 0.2)
                ],
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Floating orbs
            Circle()
                .fill(.purple.opacity(0.2))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -80, y: -100)
            
            Circle()
                .fill(.cyan.opacity(0.2))
                .frame(width: 180, height: 180)
                .blur(radius: 50)
                .offset(x: 150, y: 300)

            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Browse Birthdays")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("View by month or calendar")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Glass segmented control
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = .byMonth
                        }
                    }) {
                        Text("By Month")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedTab == .byMonth ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                selectedTab == .byMonth ?
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.thinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(.white.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                : nil
                            )
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = .calendar
                        }
                    }) {
                        Text("Calendar")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(selectedTab == .calendar ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                selectedTab == .calendar ?
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(.thinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(.white.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                : nil
                            )
                    }
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)

                if selectedTab == .byMonth {
                    ByMonthView(selectedMonth: $selectedMonth, months: months, contactsVM: contactsVM)
                } else {
                    CalendarView(selectedDate: $selectedDate, contactsVM: contactsVM)
                }

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - By Month View with Glass Effect

@available(iOS 17.0, *)
struct ByMonthView: View {
    @Binding var selectedMonth: String
    let months: [String]
    var contactsVM: ContactViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Glass month selector
            Menu {
                ForEach(months, id: \.self) { month in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMonth = month
                        }
                    }) {
                        HStack {
                            Text(month)
                            if selectedMonth == month {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .blur(radius: 12)
                        
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Month")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(selectedMonth)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .blue.opacity(0.2), radius: 15, x: 0, y: 8)
                    }
                )
                .padding(.horizontal, 24)
            }

            // Birthday list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    let contacts = contactsVM.contactsPerMonth(monthName: selectedMonth)
                    
                    if contacts.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.purple.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .blur(radius: 20)
                                
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.gray, .gray.opacity(0.6)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            
                            Text("No birthdays in \(selectedMonth)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ForEach(contacts) { contact in
                            GlassMonthContactCard(contact: contact)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Glass Month Contact Card

struct GlassMonthContactCard: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 16) {
            // Date badge with glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blur(radius: 15)
                
                VStack(spacing: 4) {
                    Text(contact.comparableBirthday?.monthAbbrev() ?? "")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(contact.comparableBirthday?.day() ?? "")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(width: 60, height: 60)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                )
            }
            
            // Contact name
            Text(contact.name)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("🎂")
                .font(.title3)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .cyan.opacity(0.15), radius: 12, x: 0, y: 6)
            }
        )
    }
}

// MARK: - Calendar View with Glass Effect

@available(iOS 17.0, *)
struct CalendarView: View {
    @Binding var selectedDate: Date
    var contactsVM: ContactViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Glass calendar picker
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding(20)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)
                    }
                )
                .padding(.horizontal, 24)
                .colorScheme(.dark)
                .tint(.cyan)

            // Selected date birthdays
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected Date")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text(selectedDate.formattedDate())
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                let contacts = contactsVM.contactsPerDate(date: selectedDate)
                
                if contacts.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(.purple.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .blur(radius: 20)
                            
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.gray, .gray.opacity(0.6)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        
                        Text("No birthdays on this date")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    VStack(spacing: 14) {
                        ForEach(contacts) { contact in
                            GlassCalendarContactCard(contact: contact, date: selectedDate)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Glass Calendar Contact Card

struct GlassCalendarContactCard: View {
    let contact: Contact
    let date: Date
    
    var body: some View {
        HStack(spacing: 16) {
            // Date badge with glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink.opacity(0.3), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .blur(radius: 15)
                
                VStack(spacing: 4) {
                    Text(date.monthAbbrev())
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(date.day())
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .pink.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(width: 60, height: 60)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    }
                )
            }
            
            // Contact name
            Text(contact.name)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("🎂")
                .font(.title3)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .pink.opacity(0.15), radius: 12, x: 0, y: 6)
            }
        )
    }
}
