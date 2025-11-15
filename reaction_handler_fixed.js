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

    // Check if user already reacted to this post
    const { data: existingReactions } = await client.database
      .from('post_reactions')
      .select('id, reaction_type')
      .eq('post_id', postId)
      .eq('user_id', userData.user.id);
    
    const existingReaction = existingReactions && existingReactions.length > 0 ? existingReactions[0] : null;

    if (existingReaction) {
      if (existingReaction.reaction_type === reactionType) {
        // User is trying to react with the same emoji - remove the reaction
        await client.database
          .from('post_reactions')
          .delete()
          .eq('id', existingReaction.id);

        // Decrement the count
        const columnMap = {
          'heart': 'heart_count',
          'laugh': 'laugh_count',
          'hot': 'hot_count',
          'broken_heart': 'broken_heart_count'
        };
        
        await client.database
          .from('shared_posts')
          .update({ [columnMap[reactionType]]: client.database.raw(`${columnMap[reactionType]} - 1`) })
          .eq('id', postId);

        return new Response(
          JSON.stringify({ 
            success: true, 
            action: 'removed',
            reactionType: reactionType 
          }),
          { status: 200, headers: corsHeaders }
        );
      } else {
        // User is changing their reaction - update it
        await client.database
          .from('post_reactions')
          .update({ reaction_type: reactionType })
          .eq('id', existingReaction.id);

        // Update counts: decrement old, increment new
        const columnMap = {
          'heart': 'heart_count',
          'laugh': 'laugh_count',
          'hot': 'hot_count',
          'broken_heart': 'broken_heart_count'
        };

        // Decrement old reaction count
        await client.database
          .from('shared_posts')
          .update({ [columnMap[existingReaction.reaction_type]]: client.database.raw(`${columnMap[existingReaction.reaction_type]} - 1`) })
          .eq('id', postId);

        // Increment new reaction count
        await client.database
          .from('shared_posts')
          .update({ [columnMap[reactionType]]: client.database.raw(`${columnMap[reactionType]} + 1`) })
          .eq('id', postId);

        return new Response(
          JSON.stringify({ 
            success: true, 
            action: 'changed',
            oldReaction: existingReaction.reaction_type,
            newReaction: reactionType 
          }),
          { status: 200, headers: corsHeaders }
        );
      }
    } else {
      // New reaction - insert it
      await client.database
        .from('post_reactions')
        .insert([{
          post_id: postId,
          user_id: userData.user.id,
          reaction_type: reactionType
        }]);

      // Increment the count
      const columnMap = {
        'heart': 'heart_count',
        'laugh': 'laugh_count',
        'hot': 'hot_count',
        'broken_heart': 'broken_heart_count'
      };
      
      await client.database
        .from('shared_posts')
        .update({ [columnMap[reactionType]]: client.database.raw(`${columnMap[reactionType]} + 1`) })
        .eq('id', postId);

      return new Response(
        JSON.stringify({ 
          success: true, 
          action: 'added',
          reactionType: reactionType 
        }),
        { status: 200, headers: corsHeaders }
      );
    }

  } catch (error) {
    console.error('Reaction handler error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: corsHeaders }
    );
  }
};