# 인증 서비스 설정 가이드

앱의 카카오/Apple 로그인이 동작하려면 아래 3개 서비스 설정이 필요합니다.

---

## 1. Supabase 프로젝트 설정

### 1-1. 프로젝트 생성
1. https://supabase.com 접속 → 회원가입
2. **New Project** 클릭 → 프로젝트 이름, 비밀번호, 리전(Northeast Asia - ap-northeast-1) 선택
3. 프로젝트 생성 완료 대기 (1-2분)

### 1-2. API 키 복사
1. **Project Settings** > **API** 메뉴
2. **Project URL** 복사 → `AppConfig.swift`의 `supabaseURL`에 입력
3. **anon (public) key** 복사 → `AppConfig.swift`의 `supabaseAnonKey`에 입력

### 1-3. 데이터베이스 테이블 생성
1. **SQL Editor** 메뉴 클릭
2. `supabase/migrations/` 폴더의 SQL 파일을 순서대로 실행:
   - `00001_create_users.sql`
   - `00002_create_fortunes.sql`
   - `00003_create_investment_profiles.sql`
   - `00004_create_coupons_and_referrals.sql`
   - `00005_create_subscriptions.sql`
   - `00006_create_education_and_push.sql`

### 1-4. Redirect URL 설정
1. **Authentication** > **URL Configuration**
2. **Redirect URLs**에 추가: `yaya://auth-callback`

### 1-5. Kakao Provider 활성화
1. **Authentication** > **Providers** > **Kakao** 클릭
2. **Enable Kakao provider** 토글 ON
3. 카카오에서 발급받은 **REST API Key** → Client ID에 입력
4. 카카오에서 생성한 **Client Secret** → Client Secret에 입력
5. Save

### 1-6. Apple Provider 활성화
1. **Authentication** > **Providers** > **Apple** 클릭
2. **Enable Apple provider** 토글 ON
3. Apple에서 생성한 **Services ID** → Client ID에 입력
4. Apple에서 생성한 **Secret Key** → Secret Key에 입력
5. Save

---

## 2. 카카오 개발자 설정

### 2-1. 앱 등록
1. https://developers.kakao.com 접속 → 로그인
2. **내 애플리케이션** > **애플리케이션 추가하기**
3. 앱 이름: `야야`, 사업자명 입력

### 2-2. 키 확인
1. **앱 설정** > **요약 정보**
2. **REST API 키** 복사 → Supabase Kakao provider의 Client ID에 사용

### 2-3. 플랫폼 등록
1. **앱 설정** > **플랫폼**
2. **iOS 플랫폼 등록** 클릭
3. **번들 ID** 입력 (Xcode에서 확인: 예 `com.yourname.Yaya`)

### 2-4. 카카오 로그인 활성화
1. **제품 설정** > **카카오 로그인**
2. **활성화 설정** → ON
3. **Redirect URI** 추가: Supabase에서 제공하는 콜백 URL
   - 형식: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`

### 2-5. Client Secret 생성
1. **제품 설정** > **카카오 로그인** > **보안**
2. **Client Secret** 코드 생성
3. **활성화 상태** → 사용함
4. 생성된 코드 → Supabase Kakao provider의 Client Secret에 입력

### 2-6. 동의 항목 설정
1. **제품 설정** > **카카오 로그인** > **동의항목**
2. **닉네임**, **프로필 사진**, **카카오계정(이메일)** → 필수 동의 또는 선택 동의로 설정

---

## 3. Apple Developer 설정

> Apple Developer 계정이 필요합니다 (연간 $99)

### 3-1. App ID 생성
1. https://developer.apple.com 접속 → **Account** → **Certificates, Identifiers & Profiles**
2. **Identifiers** > **+** 버튼 > **App IDs** 선택
3. **Bundle ID** 입력 (Xcode 프로젝트와 동일)
4. **Capabilities** 목록에서 **Sign in with Apple** 체크
5. **Register**

### 3-2. Services ID 생성 (Supabase용)
1. **Identifiers** > **+** 버튼 > **Services IDs** 선택
2. Description: `Yaya Login`, Identifier: `com.yourname.yaya.login`
3. **Sign in with Apple** 체크 → **Configure**
4. **Primary App ID**: 위에서 만든 App ID 선택
5. **Domains and Subdomains**: `YOUR_PROJECT.supabase.co`
6. **Return URLs**: `https://YOUR_PROJECT.supabase.co/auth/v1/callback`
7. Save → Register

### 3-3. Key 생성
1. **Keys** > **+** 버튼
2. Key Name: `Yaya Auth Key`
3. **Sign in with Apple** 체크 → **Configure** → 위의 App ID 선택
4. **Register** → **.p8 파일 다운로드** (한 번만 가능!)
5. **Key ID** 메모

### 3-4. Supabase에 Apple 정보 입력
1. Supabase 대시보드 > Authentication > Providers > Apple
2. **Client ID**: Services ID (예: `com.yourname.yaya.login`)
3. **Secret Key**: `.p8` 파일 내용 전체 (-----BEGIN PRIVATE KEY----- 포함)
4. **Key ID**: Apple에서 메모한 Key ID
5. **Team ID**: Apple Developer 계정 상단에 표시된 Team ID

---

## 4. AppConfig.swift 업데이트

모든 설정 완료 후 `ios/Yaya/Yaya/Config/AppConfig.swift` 파일을 수정합니다:

```swift
static let supabaseURL = "https://abcdefgh.supabase.co"  // 실제 URL
static let supabaseAnonKey = "eyJhbGciOiJ..."              // 실제 anon key
```

---

## 5. 테스트 체크리스트

- [ ] Supabase 프로젝트 생성 완료
- [ ] DB 테이블 생성 (migration SQL 실행)
- [ ] Supabase Redirect URL 설정 (`yaya://auth-callback`)
- [ ] 카카오 앱 등록 + 로그인 활성화
- [ ] 카카오 Client Secret 생성 → Supabase에 입력
- [ ] Apple App ID + Services ID + Key 생성
- [ ] Apple 정보 → Supabase에 입력
- [ ] AppConfig.swift에 실제 URL/Key 입력
- [ ] 시뮬레이터에서 Apple 로그인 테스트
- [ ] 실기기에서 카카오 로그인 테스트
