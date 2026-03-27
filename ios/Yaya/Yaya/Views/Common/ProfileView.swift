import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                // 프로필 정보
                Section {
                    if let user = authViewModel.currentUser {
                        HStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.purple)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.nickname ?? "사용자")
                                    .font(.headline)
                                Text(user.subscriptionTier.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // 사주 정보
                Section("나의 사주 정보") {
                    if let user = authViewModel.currentUser {
                        if let birthDate = user.birthDate {
                            LabeledContent("생년월일") {
                                Text(birthDate, style: .date)
                            }
                        }
                        if let birthTime = user.birthTime {
                            LabeledContent("태어난 시") {
                                Text(birthTime.displayName)
                            }
                        }
                        if let gender = user.gender {
                            LabeledContent("성별") {
                                Text(gender.displayName)
                            }
                        }
                        LabeledContent("달력") {
                            Text(user.isLunar ? "음력" : "양력")
                        }
                    }
                }

                // 추천 현황
                Section("추천 현황") {
                    if let user = authViewModel.currentUser {
                        LabeledContent("추천 코드") {
                            HStack {
                                Text(user.referralCode ?? "-")
                                    .font(.system(.body, design: .monospaced))
                                Button {
                                    if let code = user.referralCode {
                                        UIPasteboard.general.string = code
                                    }
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                            }
                        }
                        LabeledContent("추천한 친구") {
                            Text("\(user.referralCount)명 / 2명")
                        }

                        if user.referralCount < AppConfig.referralRequiredCount {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.orange)
                                Text("2명 추천 시 2주마다 3,000원 쿠폰 지급!")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }

                // 구독 관리
                Section("구독 관리") {
                    NavigationLink {
                        // TODO: SubscriptionView
                        Text("구독 관리 화면")
                    } label: {
                        Label("구독 등급 변경", systemImage: "crown")
                    }

                    NavigationLink {
                        // TODO: CouponListView
                        Text("쿠폰 목록")
                    } label: {
                        Label("내 쿠폰", systemImage: "ticket")
                    }
                }

                // 설정
                Section("설정") {
                    NavigationLink {
                        Text("알림 설정")
                    } label: {
                        Label("알림 설정", systemImage: "bell")
                    }

                    NavigationLink {
                        Text("이용약관")
                    } label: {
                        Label("이용약관", systemImage: "doc.text")
                    }

                    NavigationLink {
                        Text("개인정보 처리방침")
                    } label: {
                        Label("개인정보 처리방침", systemImage: "hand.raised")
                    }
                }

                // 로그아웃
                Section {
                    Button(role: .destructive) {
                        Task { await authViewModel.signOut() }
                    } label: {
                        Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("마이페이지")
        }
    }
}
