import React from 'react';

interface CalculatorResultsProps {
  totalReturn: number;
  savings: number;
}

const CalculatorResults: React.FC<CalculatorResultsProps> = ({ totalReturn, savings }) => {
  return (
    <div className="bg-expert-navy text-white p-10 rounded-3xl relative overflow-hidden">
      <div className="absolute top-0 right-0 w-32 h-32 bg-primary/20 blur-3xl"></div>

      <h3 className="text-sm font-black uppercase tracking-widest mb-2 opacity-60 text-sunshine-yellow">
        Projected Monthly Value
      </h3>

      <div className="text-6xl font-display font-black mb-6">
        ${totalReturn.toLocaleString(undefined, { maximumFractionDigits: 0 })}
      </div>

      <p className="text-sm leading-relaxed opacity-70 italic mb-8">
        Based on a 15% efficiency gain and {savings * 4} hours of reclaimed admin time per month.
      </p>

      <button className="w-full bg-primary py-4 rounded-xl font-bold text-lg hover:scale-105 transition-transform">
        Get the Custom Report
      </button>
    </div>
  );
};

export default CalculatorResults;
