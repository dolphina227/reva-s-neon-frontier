
-- Create users table for waitlist
CREATE TABLE public.users (
  wallet TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  twitter_username TEXT NOT NULL,
  points INTEGER NOT NULL DEFAULT 10000,
  joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create quests table
CREATE TABLE public.quests (
  quest_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  reward_points INTEGER NOT NULL DEFAULT 200,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  quest_link TEXT,
  created_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create completed_quests table
CREATE TABLE public.completed_quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet TEXT NOT NULL REFERENCES public.users(wallet) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.quests(quest_id) ON DELETE CASCADE,
  completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(wallet, quest_id)
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completed_quests ENABLE ROW LEVEL SECURITY;

-- Public read access for all tables (transparent data)
CREATE POLICY "Anyone can view users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Anyone can view quests" ON public.quests FOR SELECT USING (true);
CREATE POLICY "Anyone can view completed_quests" ON public.completed_quests FOR SELECT USING (true);

-- Insert policies
CREATE POLICY "Anyone can register" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can complete quests" ON public.completed_quests FOR INSERT WITH CHECK (true);

-- Update policies (admin-only logic will be handled in frontend)
CREATE POLICY "Anyone can update users" ON public.users FOR UPDATE USING (true);
CREATE POLICY "Anyone can manage quests" ON public.quests FOR ALL USING (true);

-- Enable realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
ALTER PUBLICATION supabase_realtime ADD TABLE public.quests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.completed_quests;

-- Create function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for quests
CREATE TRIGGER update_quests_updated_at
BEFORE UPDATE ON public.quests
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();
