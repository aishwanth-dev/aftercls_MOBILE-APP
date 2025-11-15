module.exports = async function(request) {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const authHeader = request.headers.get('Authorization');
    const userToken = authHeader ? authHeader.replace('Bearer ', '') : null;
    
    const client = createClient({ 
      baseUrl: Deno.env.get('BACKEND_INTERNAL_URL') || 'http://insforge:7130',
      edgeFunctionToken: userToken
    });

    const { data: userData } = await client.auth.getCurrentUser();
    if (!userData?.user?.id) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: corsHeaders }
      );
    }

    const body = await request.json();
    const { postId, reactionType } = body;

    if (!postId || !reactionType) {
      return new Response(
        JSON.stringify({ error: 'Missing postId or reactionType' }),
        { status: 400, headers: corsHeaders }
      );
    }

    const validReactions = ['heart', 'laugh', 'hot', 'broken_heart'];
    if (!validReactions.includes(reactionType)) {
      return new Response(
        JSON.stringify({ error: 'Invalid reaction type' }),
        { status: 400, headers: corsHeaders }
      );
    }

    const { error: rpcError } = await client.database.rpc('handle_post_reaction', {
      post_id_in: postId,
      user_id_in: userData.user.id,
      reaction_type_in: reactionType
    });

    if (rpcError) {
      console.error('RPC error:', rpcError);
      return new Response(
        JSON.stringify({ error: 'Failed to handle reaction', details: rpcError.message }),
        { status: 500, headers: corsHeaders }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: corsHeaders }
    );

  } catch (error) {
    console.error('Detailed error in handle-reaction:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: corsHeaders }
    );
  }
};