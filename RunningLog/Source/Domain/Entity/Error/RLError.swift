//
//  RLError.swift
//  RunningLog
//
//  Created by Den on 6/1/25.
//

import Foundation

enum RLError: Error {
    case statusCodeError(statusCode: Int)
    case unKnown
    case unknown
    case httpURLResponse
    case repositoryError
    case useCaseError
    case decodingError(error: Error)
    case invalidParameter
    case invalidSearch
    case systemError
    case locationPermissionDenied
    case locationUnavailable
}

extension RLError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .statusCodeError(let statusCode):
            return "상태코드 이상 \(statusCode)"
        case .httpURLResponse:
            return "URL 확인"
        case .unKnown:
            return "미확인 오류"
        case .unknown:
            return "알 수 없는 오류"
        case .repositoryError:
            return "repository 확인 필요"
        case .useCaseError:
            return "useCase 확인 필요"
        case .decodingError(let error):
            return "\(error)"
        case .invalidParameter:
            return "파라미터 오류 (쿼리 / 디스플레이 / start / sort / 인코딩)"
        case .invalidSearch:
            return "존재하지 않는 검색 API (API 요청 URL에 오타가 있는 지 확인)"
        case .systemError:
            return "서버 내부에 오류 발생해서 개발자 포럼에 신고하라고 함"
        case .locationPermissionDenied:
            return "위치 권한이 거부되었습니다"
        case .locationUnavailable:
            return "위치 정보를 가져올 수 없습니다"
        }
    }
}
