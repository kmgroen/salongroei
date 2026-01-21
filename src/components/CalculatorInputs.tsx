import React from 'react';
import RangeSlider from './RangeSlider';

interface CalculatorInputsProps {
  revenue: number;
  savings: number;
  onRevenueChange: (value: number) => void;
  onSavingsChange: (value: number) => void;
}

const CalculatorInputs: React.FC<CalculatorInputsProps> = ({
  revenue,
  savings,
  onRevenueChange,
  onSavingsChange,
}) => {
  return (
    <div className="space-y-8">
      <RangeSlider
        label="Monthly Revenue"
        min={1000}
        max={50000}
        step={500}
        value={revenue}
        onChange={onRevenueChange}
        minLabel="$1k"
        maxLabel="$50k"
        valueFormatter={(val) => `$${val.toLocaleString()}`}
        accentColor="primary"
      />

      <RangeSlider
        label="Hours Saved per Week"
        min={1}
        max={40}
        step={1}
        value={savings}
        onChange={onSavingsChange}
        minLabel="1hr"
        maxLabel="40hrs"
        valueFormatter={(val) => `${val} hours`}
        accentColor="soft-sage"
      />
    </div>
  );
};

export default CalculatorInputs;
