import React, { useState } from 'react';
import CalculatorInputs from './CalculatorInputs';
import CalculatorResults from './CalculatorResults';

const CalculatorForm: React.FC = () => {
  const [revenue, setRevenue] = useState(5000);
  const [savings, setSavings] = useState(10);

  const totalReturn = (revenue * 0.15) + (savings * 4 * 50);

  return (
    <div className="max-w-[900px] mx-auto bg-white rounded-[3rem] p-12 shadow-2xl shadow-expert-navy/5 border border-expert-navy/5">
      <header className="text-center mb-12">
        <h1 className="font-display text-4xl font-black mb-4">ROI Calculator</h1>
        <p className="text-expert-navy/60">Estimate how much you'll save by switching to the right salon software.</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
        <CalculatorInputs
          revenue={revenue}
          savings={savings}
          onRevenueChange={setRevenue}
          onSavingsChange={setSavings}
        />

        <CalculatorResults
          totalReturn={totalReturn}
          savings={savings}
        />
      </div>
    </div>
  );
};

export default CalculatorForm;
