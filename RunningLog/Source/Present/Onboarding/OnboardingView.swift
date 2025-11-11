//
//  OnboardingView.swift
//  RunningLog
//
//  Created by Den on 11/11/25.
//


import SwiftUI
import ComposableArchitecture

struct OnboardingCardView: View {
    let data: OnboardingData

    var body: some View {
        VStack {
            // 아이콘 영역
            ZStack {
                Circle()
                    .fill(data.iconColor)
                    .frame(width: 120, height: 120)
                
                Image(systemName: data.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
            }
            .padding(.bottom, 60)

            // 제목
            Text(data.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 10)

            // 설명
            Text(data.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top, 100)
        .padding(.horizontal)
    }
}

struct CustomOnboardingView: View {
    @State private var currentPage = 0
    
    let pages: [OnboardingData] = [
        OnboardingData(
            iconName: "waveform.path.ecg",
            title: "러닝을 기록하세요",
            description: "GPS를 통해 실시간으로 러닝 경로와 데이터를 추적합니다",
            iconColor: Color.mainColor
        ),
        OnboardingData(
            iconName: "location.fill",
            title: "목표를 달성하세요",
            description: "주간, 월간 목표를 설정하고 달성률을 확인하세요",
            iconColor: Color.mainColor
        ),
        OnboardingData(
            iconName: "location.fill",
            title: "로컬에 안전하게 저장",
            description: "모든 데이터는 기기에만 저장되어 안전하게 보호됩니다",
            iconColor: Color.mainColor
        )
    ]
    
    // 주황색 그라데이션 배경 정의
    let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.gradientOrange,  // 아주 연한 주황색
            Color.white // 연한 베이지/흰색
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    private func goToNextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut) {
                currentPage += 1
            }
        } else {
            print("온보딩 완료. 메인 화면으로 이동합니다.")
        }
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingCardView(data: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                
                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ?
                                      Color.mainColor :
                                      Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 25 : 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)

                    // '다음' 버튼
                    Button(action: goToNextPage) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "다음" : "시작하기")
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            Color.mainColor
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// MARK: - 미리보기 (Preview)
struct CustomOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        CustomOnboardingView()
    }
}
