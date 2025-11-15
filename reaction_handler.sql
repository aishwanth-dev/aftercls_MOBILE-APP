CREATE OR REPLACE FUNCTION handle_post_reaction(
    post_id_in uuid,
    user_id_in uuid,
    reaction_type_in text
)
RETURNS void AS $$
DECLARE
    existing_reaction_type text;
BEGIN
    -- Check if a reaction already exists from this user for this post
    SELECT reaction_type INTO existing_reaction_type
    FROM public.post_reactions
    WHERE post_id = post_id_in AND user_id = user_id_in;

    IF FOUND THEN
        -- If the new reaction is the same as the old one, un-react
        IF existing_reaction_type = reaction_type_in THEN
            -- Delete the reaction
            DELETE FROM public.post_reactions
            WHERE post_id = post_id_in AND user_id = user_id_in;

            -- Decrement the count in shared_posts
            EXECUTE 'UPDATE public.shared_posts SET ' || reaction_type_in || '_count = ' || reaction_type_in || '_count - 1 WHERE id = $1'
            USING post_id_in;
        ELSE
            -- If the new reaction is different, update the reaction
            UPDATE public.post_reactions
            SET reaction_type = reaction_type_in
            WHERE post_id = post_id_in AND user_id = user_id_in;

            -- Decrement the old reaction count
            EXECUTE 'UPDATE public.shared_posts SET ' || existing_reaction_type || '_count = ' || existing_reaction_type || '_count - 1 WHERE id = $1'
            USING post_id_in;

            -- Increment the new reaction count
            EXECUTE 'UPDATE public.shared_posts SET ' || reaction_type_in || '_count = ' || reaction_type_in || '_count + 1 WHERE id = $1'
            USING post_id_in;
        END IF;
    ELSE
        -- If no reaction exists, insert a new one
        INSERT INTO public.post_reactions (post_id, user_id, reaction_type)
        VALUES (post_id_in, user_id_in, reaction_type_in);

        -- Increment the count in shared_posts
        EXECUTE 'UPDATE public.shared_posts SET ' || reaction_type_in || '_count = ' || reaction_type_in || '_count + 1 WHERE id = $1'
        USING post_id_in;
    END IF;
END;
$$ LANGUAGE plpgsql;