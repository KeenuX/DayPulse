import React from 'react';
import {
  BookOpen,
  Code2,
  Briefcase,
  Dumbbell,
  Home,
  Rocket,
  Pin,
  Music,
  Palette,
  Coffee,
  Gamepad2,
  ShoppingBag,
  HeartPulse,
  DollarSign,
  Globe,
  Folder,
  LucideProps,
} from 'lucide-react';

interface CategoryIconProps extends LucideProps {
  iconName?: string;
}

export const CategoryIcon: React.FC<CategoryIconProps> = ({ iconName, ...props }) => {
  switch (iconName) {
    case 'BookOpen':
      return <BookOpen {...props} />;
    case 'Code2':
      return <Code2 {...props} />;
    case 'Briefcase':
      return <Briefcase {...props} />;
    case 'Dumbbell':
      return <Dumbbell {...props} />;
    case 'Home':
      return <Home {...props} />;
    case 'Rocket':
      return <Rocket {...props} />;
    case 'Pin':
      return <Pin {...props} />;
    case 'Music':
      return <Music {...props} />;
    case 'Palette':
      return <Palette {...props} />;
    case 'Coffee':
      return <Coffee {...props} />;
    case 'Gamepad2':
      return <Gamepad2 {...props} />;
    case 'ShoppingBag':
      return <ShoppingBag {...props} />;
    case 'HeartPulse':
      return <HeartPulse {...props} />;
    case 'DollarSign':
      return <DollarSign {...props} />;
    case 'Globe':
      return <Globe {...props} />;
    case 'Folder':
    default:
      return <Folder {...props} />;
  }
};
