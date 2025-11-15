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

    // Align with app reaction names
    const validReactions = ['heart', 'laugh', 'hot', 'broken_heart'];
    if (!validReactions.includes(reactionType)) {
      return new Response(
        JSON.stringify({ error: 'Invalid reaction type' }),
        { status: 400, headers: corsHeaders }
      );
    }

    // One reaction per user per post: allow changing to a different emoji
    const { data: existingReaction } = await client.database
      .from('shared_post_reactions')
      .select('id, reaction')
      .eq('post_id', postId)
      .eq('user_id', userData.user.id)
      .single();

    const typeToColumn = {
      heart: 'heart_count',
      laugh: 'laugh_count',
      hot: 'hot_count',
      broken_heart: 'broken_heart_count',
    };

    // Normalize legacy emoji values stored in DB
    const emojiToType = {
      '❤️': 'heart',
      '😂': 'laugh',
      '🥵': 'hot',
      '💔': 'broken_heart',
    };

    if (existingReaction) {
      const existing = existingReaction.reaction;
      const existingType = emojiToType[existing] || existing; // normalize

      if (existingType === reactionType) {
        // Same reaction tapped again → no change
        return new Response(
          JSON.stringify({ success: true, action: 'no_change', reactionType }),
          { status: 200, headers: corsHeaders }
        );
      }

      // Change reaction: decrement old, increment new, and update the row
      const oldColumn = typeToColumn[existingType];
      const newColumn = typeToColumn[reactionType];

      // Fetch current counts
      const { data: postData } = await client.database
        .from('shared_posts')
        .select(`${oldColumn}, ${newColumn}`)
        .eq('id', postId)
        .single();

      const oldCount = postData && typeof postData[oldColumn] === 'number' ? postData[oldColumn] : 0;
      const newCount = postData && typeof postData[newColumn] === 'number' ? postData[newColumn] : 0;

      // Update both counts
      await client.database
        .from('shared_posts')
        .update({
          [oldColumn]: Math.max(0, oldCount - 1),
          [newColumn]: newCount + 1,
        })
        .eq('id', postId);

      // Update reaction row to new type (store canonical type string)
      await client.database
        .from('shared_post_reactions')
        .update({ reaction: reactionType })
        .eq('id', existingReaction.id);

      return new Response(
        JSON.stringify({ success: true, action: 'changed', from: existingType, to: reactionType }),
        { status: 200, headers: corsHeaders }
      );
    }

    // No existing reaction → insert and increment new count
    await client.database
      .from('shared_post_reactions')
      .insert([{ post_id: postId, user_id: userData.user.id, reaction: reactionType }]);

    const newCountField = typeToColumn[reactionType];
    const { data: postData2 } = await client.database
      .from('shared_posts')
      .select(newCountField)
      .eq('id', postId)
      .single();

    const baseCount = postData2 && typeof postData2[newCountField] === 'number' ? postData2[newCountField] : 0;

    await client.database
      .from('shared_posts')
      .update({ [newCountField]: baseCount + 1 })
      .eq('id', postId);

    return new Response(
      JSON.stringify({ success: true, action: 'added', reactionType }),
      { status: 200, headers: corsHeaders }
    );
  
  } catch (error) {
    console.error('Reaction handler error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: corsHeaders }
    );
  }
};
