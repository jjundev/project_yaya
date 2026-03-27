import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface KakaoUser {
  id: number;
  kakao_account?: {
    email?: string;
    profile?: {
      nickname?: string;
      profile_image_url?: string;
    };
  };
  properties?: {
    nickname?: string;
    profile_image?: string;
  };
}

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { access_token } = await req.json();

    if (!access_token) {
      return new Response(
        JSON.stringify({ error: "access_token is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. 카카오 API로 토큰 검증 및 사용자 정보 조회
    const kakaoRes = await fetch("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${access_token}` },
    });

    if (!kakaoRes.ok) {
      return new Response(
        JSON.stringify({ error: "Invalid Kakao access token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const kakaoUser: KakaoUser = await kakaoRes.json();
    const kakaoId = String(kakaoUser.id);
    const email =
      kakaoUser.kakao_account?.email || `kakao_${kakaoId}@kakao.user`;
    const nickname =
      kakaoUser.kakao_account?.profile?.nickname ||
      kakaoUser.properties?.nickname ||
      null;
    const avatarUrl =
      kakaoUser.kakao_account?.profile?.profile_image_url ||
      kakaoUser.properties?.profile_image ||
      null;

    // 2. Supabase Admin 클라이언트 생성
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // 3. 기존 유저 조회 (kakao_id로)
    const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
    let user = existingUsers?.users?.find(
      (u) => u.user_metadata?.kakao_id === kakaoId
    );

    if (!user) {
      // 이메일로도 조회 시도
      user = existingUsers?.users?.find(
        (u) => u.email === email
      );
    }

    if (!user) {
      // 4a. 새 유저 생성
      const { data: newUser, error: createError } =
        await supabaseAdmin.auth.admin.createUser({
          email,
          email_confirm: true,
          user_metadata: {
            provider: "kakao",
            kakao_id: kakaoId,
            nickname,
            avatar_url: avatarUrl,
          },
        });

      if (createError) {
        throw new Error(`Failed to create user: ${createError.message}`);
      }
      user = newUser.user;
    } else {
      // 4b. 기존 유저 메타데이터 업데이트
      await supabaseAdmin.auth.admin.updateUserById(user.id, {
        user_metadata: {
          ...user.user_metadata,
          provider: "kakao",
          kakao_id: kakaoId,
          nickname: nickname || user.user_metadata?.nickname,
          avatar_url: avatarUrl || user.user_metadata?.avatar_url,
        },
      });
    }

    // 5. Magic Link 토큰 생성 (OTP로 세션 생성용)
    const { data: linkData, error: linkError } =
      await supabaseAdmin.auth.admin.generateLink({
        type: "magiclink",
        email: user.email!,
      });

    if (linkError) {
      throw new Error(`Failed to generate link: ${linkError.message}`);
    }

    // 6. 클라이언트에 토큰 반환
    return new Response(
      JSON.stringify({
        email: user.email,
        token: linkData.properties.hashed_token,
        user_id: user.id,
        kakao_id: kakaoId,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
