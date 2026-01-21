import React from 'react';

interface RangeSliderProps {
  label: string;
  min: number;
  max: number;
  step: number;
  value: number;
  onChange: (value: number) => void;
  minLabel: string;
  maxLabel: string;
  valueFormatter: (value: number) => string;
  accentColor: 'primary' | 'soft-sage';
}

const RangeSlider: React.FC<RangeSliderProps> = ({
  label,
  min,
  max,
  step,
  value,
  onChange,
  minLabel,
  maxLabel,
  valueFormatter,
  accentColor,
}) => {
  const accentColorClass = accentColor === 'primary' ? 'text-primary accent-primary' : 'text-soft-sage accent-soft-sage';

  return (
    <div className="space-y-4">
      <label className="block text-sm font-bold uppercase tracking-widest text-primary">
        {label}
      </label>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        onChange={(e) => onChange(parseInt(e.target.value))}
        className={`w-full ${accentColorClass}`}
      />
      <div className="flex justify-between text-xl font-display font-black">
        <span>{minLabel}</span>
        <span className={accentColorClass}>
          {valueFormatter(value)}
        </span>
        <span>{maxLabel}</span>
      </div>
    </div>
  );
};

export default RangeSlider;
