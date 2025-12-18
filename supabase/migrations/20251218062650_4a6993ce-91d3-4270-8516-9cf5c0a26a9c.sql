-- Create referral_codes table to store unique codes for each user
CREATE TABLE public.referral_codes (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  wallet TEXT NOT NULL REFERENCES public.users(wallet) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  uses_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create referrals table to track who referred whom
CREATE TABLE public.referrals (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  referrer_wallet TEXT NOT NULL REFERENCES public.users(wallet) ON DELETE CASCADE,
  referred_wallet TEXT NOT NULL REFERENCES public.users(wallet) ON DELETE CASCADE,
  referral_code TEXT NOT NULL REFERENCES public.referral_codes(code) ON DELETE CASCADE,
  points_awarded INTEGER NOT NULL DEFAULT 2500,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(referred_wallet)
);

-- Enable RLS on both tables
ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- RLS policies for referral_codes (public read, users can create their own)
CREATE POLICY "Anyone can view referral codes" 
ON public.referral_codes 
FOR SELECT 
USING (true);

CREATE POLICY "Anyone can create referral codes" 
ON public.referral_codes 
FOR INSERT 
WITH CHECK (true);

CREATE POLICY "Anyone can update referral codes" 
ON public.referral_codes 
FOR UPDATE 
USING (true);

-- RLS policies for referrals (public read, anyone can create)
CREATE POLICY "Anyone can view referrals" 
ON public.referrals 
FOR SELECT 
USING (true);

CREATE POLICY "Anyone can create referrals" 
ON public.referrals 
FOR INSERT 
WITH CHECK (true);

-- Create indexes for better performance
CREATE INDEX idx_referral_codes_wallet ON public.referral_codes(wallet);
CREATE INDEX idx_referral_codes_code ON public.referral_codes(code);
CREATE INDEX idx_referrals_referrer ON public.referrals(referrer_wallet);
CREATE INDEX idx_referrals_referred ON public.referrals(referred_wallet);

-- Enable realtime for both tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.referral_codes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.referrals;

-- Create function to generate unique referral code
CREATE OR REPLACE FUNCTION public.generate_referral_code()
RETURNS TEXT
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN 'NOXA-' || result;
END;
$$;

-- Create function to auto-generate 6 referral codes when user registers
CREATE OR REPLACE FUNCTION public.create_user_referral_codes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  i INTEGER;
  new_code TEXT;
BEGIN
  FOR i IN 1..6 LOOP
    LOOP
      new_code := generate_referral_code();
      BEGIN
        INSERT INTO public.referral_codes (wallet, code)
        VALUES (NEW.wallet, new_code);
        EXIT;
      EXCEPTION WHEN unique_violation THEN
        -- Code already exists, generate a new one
        CONTINUE;
      END;
    END LOOP;
  END LOOP;
  RETURN NEW;
END;
$$;

-- Create trigger to auto-generate codes on user registration
CREATE TRIGGER on_user_created_generate_referral_codes
  AFTER INSERT ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.create_user_referral_codes();

-- Create function to process referral and award points
CREATE OR REPLACE FUNCTION public.process_referral(
  p_referral_code TEXT,
  p_referred_wallet TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_referrer_wallet TEXT;
  v_already_referred BOOLEAN;
BEGIN
  -- Check if user was already referred
  SELECT EXISTS(SELECT 1 FROM public.referrals WHERE referred_wallet = p_referred_wallet)
  INTO v_already_referred;
  
  IF v_already_referred THEN
    RETURN FALSE;
  END IF;
  
  -- Get referrer wallet from code
  SELECT wallet INTO v_referrer_wallet
  FROM public.referral_codes
  WHERE code = p_referral_code;
  
  IF v_referrer_wallet IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Cannot refer yourself
  IF v_referrer_wallet = p_referred_wallet THEN
    RETURN FALSE;
  END IF;
  
  -- Create referral record
  INSERT INTO public.referrals (referrer_wallet, referred_wallet, referral_code, points_awarded)
  VALUES (v_referrer_wallet, p_referred_wallet, p_referral_code, 2500);
  
  -- Update referral code uses count
  UPDATE public.referral_codes
  SET uses_count = uses_count + 1
  WHERE code = p_referral_code;
  
  -- Award points to referrer
  UPDATE public.users
  SET points = points + 2500
  WHERE wallet = v_referrer_wallet;
  
  RETURN TRUE;
END;
$$;