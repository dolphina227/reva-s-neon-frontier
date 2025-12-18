
-- Reset all data
TRUNCATE TABLE public.referrals CASCADE;
TRUNCATE TABLE public.referral_codes CASCADE;
TRUNCATE TABLE public.completed_quests CASCADE;
TRUNCATE TABLE public.users CASCADE;

-- Drop existing trigger
DROP TRIGGER IF EXISTS create_referral_codes_trigger ON public.users;

-- Update function to create only 1 code per user
CREATE OR REPLACE FUNCTION public.create_user_referral_codes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_code TEXT;
BEGIN
  -- Generate only 1 unique code
  LOOP
    new_code := generate_referral_code();
    BEGIN
      INSERT INTO public.referral_codes (wallet, code)
      VALUES (NEW.wallet, new_code);
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      CONTINUE;
    END;
  END LOOP;
  RETURN NEW;
END;
$$;

-- Recreate trigger
CREATE TRIGGER create_referral_codes_trigger
AFTER INSERT ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.create_user_referral_codes();
