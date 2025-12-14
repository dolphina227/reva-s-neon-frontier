import { Pickaxe } from 'lucide-react';

export default function Mine() {
  return (
    <div className="min-h-screen bg-background pt-24 px-6">
      <div className="container mx-auto max-w-4xl">
        <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
          <div className="w-24 h-24 rounded-full bg-layer-2 flex items-center justify-center mb-6 animate-pulse">
            <Pickaxe className="w-12 h-12 text-secondary" />
          </div>
          <h1 className="text-4xl md:text-5xl font-display font-bold text-foreground mb-4">
            Mine
          </h1>
          <p className="text-xl text-secondary font-medium mb-2">Coming Soon</p>
          <p className="text-muted-foreground max-w-md">
            Something exciting is being built. Stay tuned for updates!
          </p>
        </div>
      </div>
    </div>
  );
}
