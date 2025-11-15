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
    // Create client with anon token for cleanup (no user authentication needed)
    const client = createClient({ 
      baseUrl: Deno.env.get('BACKEND_INTERNAL_URL') || 'http://insforge:7130',
      edgeFunctionToken: Deno.env.get('ACCESS_API_KEY') || null
    });

    // Delete all expired posts (where expires_at < current timestamp)
    const { data, error } = await client.database
      .from('shared_posts')
      .delete()
      .lt('expires_at', new Date().toISOString());

    if (error) {
      console.error('Error deleting expired posts:', error);
      return new Response(
        JSON.stringify({ error: 'Failed to delete expired posts', details: error.message }),
        { status: 500, headers: corsHeaders }
      );
    }

    console.log(`Successfully deleted expired posts`);
    
    return new Response(
      JSON.stringify({ success: true, message: 'Expired posts cleaned up successfully' }),
      { status: 200, headers: corsHeaders }
    );

  } catch (error) {
    console.error('Detailed error in cleanup-expired-posts:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: corsHeaders }
    );
  }
};