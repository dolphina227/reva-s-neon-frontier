import { useState, useEffect } from 'react';
import { Quest } from '@/lib/supabase';
import { ExternalLink, Check, Loader2, Zap, Lock } from 'lucide-react';

interface QuestCardProps {
  quest: Quest;
  completed: boolean;
  onComplete: () => Promise<void>;
}

export function QuestCard({ quest, completed, onComplete }: QuestCardProps) {
  const [loading, setLoading] = useState(false);
  const [linkVisited, setLinkVisited] = useState(false);

  // Check localStorage for visited status on mount
  useEffect(() => {
    const visitedKey = `quest_visited_${quest.quest_id}`;
    const visited = localStorage.getItem(visitedKey);
    if (visited === 'true') {
      setLinkVisited(true);
    }
  }, [quest.quest_id]);

  const handleVisitLink = () => {
    if (quest.quest_link) {
      const visitedKey = `quest_visited_${quest.quest_id}`;
      localStorage.setItem(visitedKey, 'true');
      setLinkVisited(true);
      window.open(quest.quest_link, '_blank', 'noopener,noreferrer');
    }
  };

  const handleComplete = async () => {
    setLoading(true);
    try {
      await onComplete();
      // Clear visited status after completion
      const visitedKey = `quest_visited_${quest.quest_id}`;
      localStorage.removeItem(visitedKey);
    } finally {
      setLoading(false);
    }
  };

  const canComplete = !quest.quest_link || linkVisited;

  return (
    <div 
      className={`card-neon transition-all duration-300 ${
        completed ? 'opacity-70' : ''
      }`}
    >
      <div className="flex items-start justify-between gap-6">
        <div className="flex-1">
          <div className="flex items-center gap-3 mb-2">
            <div className="p-2 rounded-lg bg-primary/10">
              <Zap className="w-4 h-4 text-primary" />
            </div>
            <h3 className="font-display font-semibold text-lg">{quest.title}</h3>
          </div>
          <p className="text-muted-foreground text-sm mb-4">
            {quest.description}
          </p>
          
          <div className="flex items-center gap-3">
            <span className="px-3 py-1 rounded-full bg-secondary/10 text-secondary text-sm font-semibold">
              +{quest.reward_points} pts
            </span>
            {quest.status === 'inactive' && (
              <span className="px-3 py-1 rounded-full bg-muted text-muted-foreground text-sm">
                Inactive
              </span>
            )}
          </div>
        </div>

        <div className="flex flex-col gap-2 min-w-[140px]">
          {quest.quest_link && (
            <button
              onClick={handleVisitLink}
              disabled={completed}
              className={`btn-neon-outline text-sm px-4 py-2 flex items-center justify-center gap-2 ${
                linkVisited && !completed ? 'border-green-500/50 text-green-400' : ''
              } ${completed ? 'opacity-50 cursor-not-allowed' : ''}`}
            >
              <ExternalLink className={`w-4 h-4 ${linkVisited && !completed ? 'text-green-400' : 'text-secondary'}`} />
              {linkVisited && !completed ? 'Visited' : 'Visit Link'}
            </button>
          )}
          
          {completed ? (
            <div className="px-4 py-2 rounded-xl bg-green-500/10 text-green-400 font-semibold text-sm flex items-center justify-center gap-2">
              <Check className="w-4 h-4" />
              Completed
            </div>
          ) : (
            <button
              onClick={handleComplete}
              disabled={loading || quest.status === 'inactive' || !canComplete}
              className="btn-neon text-sm px-4 py-2 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none flex items-center justify-center gap-2"
              title={!canComplete ? 'Visit the link first to complete this quest' : ''}
            >
              {loading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : !canComplete ? (
                <>
                  <Lock className="w-4 h-4" />
                  Complete
                </>
              ) : (
                'Complete'
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
}