//
//  OnboardingView.swift
//  RunningLog
//
//  Created by Den on 11/11/25.
//


import SwiftUI
import ComposableArchitecture


struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>
    
    private func buttonText(for currentPage: Int, pageCount: Int) -> String {
        return currentPage < pageCount - 1 ? "다음" : "시작하기"
    }

    private let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.gradientOrange,
            Color.white
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    TabView(selection: viewStore.binding(
                        get: \.currentPage,
                        send: OnboardingFeature.Action.pageChanged
                    )) {
                        ForEach(viewStore.onboardingData.indices, id: \.self) { index in
                            OnboardingCardView(data: viewStore.onboardingData[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    
                    VStack(spacing: 20) {
                        HStack(spacing: 8) {
                            ForEach(viewStore.onboardingData.indices, id: \.self) { index in
                                Capsule()
                                    .fill(index == viewStore.currentPage ?
                                          Color.mainColor :
                                          Color.gray.opacity(0.3))
                                    .frame(width: index == viewStore.currentPage ? 25 : 8, height: 8)
                                    .animation(.spring(), value: viewStore.currentPage)
                            }
                        }
                        .padding(.bottom, 20)
                        
                        Button {
                            viewStore.send(.nextButtonTapped, animation: .easeInOut)
                        } label: {
                            Text(buttonText(for: viewStore.currentPage, pageCount: viewStore.onboardingData.count))
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.mainColor)
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
}


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

