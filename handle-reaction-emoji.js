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

    // Map string reaction types to emojis
    const reactionEmojiMap = {
      'heart': '❤️',
      'laugh': '😂',
      'hot': '🥵',
      'broken_heart': '💔'
    };

    const emojiReaction = reactionEmojiMap[reactionType];

    // Check if user already has a reaction on this post
    const { data: existingReaction } = await client.database
      .from('shared_post_reactions')
      .select('*')
      .eq('post_id', postId)
      .eq('user_id', userData.user.id)
      .single();

    if (existingReaction) {
      // User already has a reaction - remove it if it's the same type, or update if different
      if (existingReaction.reaction === emojiReaction) {
        // Remove the reaction
        await client.database
          .from('shared_post_reactions')
          .delete()
          .eq('id', existingReaction.id);

        // Decrement the count in shared_posts
        const countField = `${reactionType}_count`;
        const { data: postData } = await client.database
          .from('shared_posts')
          .select(countField)
          .eq('id', postId)
          .single();

        if (postData && postData[countField] > 0) {
          await client.database
            .from('shared_posts')
            .update({ [countField]: postData[countField] - 1 })
            .eq('id', postId);
        }
      } else {
        // Update to different reaction type
        const oldReactionType = existingReaction.reaction;
        
        // Map the old emoji back to string type for count updates
        const reverseEmojiMap = {
          '❤️': 'heart',
          '😂': 'laugh',
          '🥵': 'hot',
          '💔': 'broken_heart'
        };
        
        const oldReactionString = reverseEmojiMap[oldReactionType] || reactionType;
        
        // Update the reaction
        await client.database
          .from('shared_post_reactions')
          .update({ reaction: emojiReaction })
          .eq('id', existingReaction.id);

        // Decrement old count
        const oldCountField = `${oldReactionString}_count`;
        const { data: postData } = await client.database
          .from('shared_posts')
          .select(oldCountField)
          .eq('id', postId)
          .single();

        if (postData && postData[oldCountField] > 0) {
          await client.database
            .from('shared_posts')
            .update({ [oldCountField]: postData[oldCountField] - 1 })
            .eq('id', postId);
        }

        // Increment new count
        const newCountField = `${reactionType}_count`;
        const { data: postData2 } = await client.database
          .from('shared_posts')
          .select(newCountField)
          .eq('id', postId)
          .single();

        if (postData2) {
          await client.database
            .from('shared_posts')
            .update({ [newCountField]: (postData2[newCountField] || 0) + 1 })
            .eq('id', postId);
        }
      }
    } else {
      // No existing reaction - add new one
      await client.database
        .from('shared_post_reactions')
        .insert([{
          post_id: postId,
          user_id: userData.user.id,
          reaction: emojiReaction
        }]);

      // Increment the count in shared_posts
      const countField = `${reactionType}_count`;
      const { data: postData } = await client.database
        .from('shared_posts')
        .select(countField)
        .eq('id', postId)
          .single();

      if (postData) {
        await client.database
          .from('shared_posts')
          .update({ [countField]: (postData[countField] || 0) + 1 })
          .eq('id', postId);
      }
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